package banking.jdbc;

import java.sql.SQLException;
import java.sql.Types;


public class UpdateBank extends MyConnection {

	public UpdateBank() {
		super("education", "1234");
	}
	String query;
	int result;
	
	@Override
	public void dbExecute() {
		
		try {
			int scan = Integer.parseInt(inputValue("1. 입금 2. 출금"));
			switch(scan) {
			case 1:
				query = "update banking "
					+"set balnc= balnc + ?"
					+" where accNum=?";
				psmt = con.prepareStatement(query);
				psmt.setString(2, inputValue("입금할 계좌번호"));
				psmt.setInt(1, Integer.parseInt(inputValue("입금할 금액")));
				
				result = psmt.executeUpdate();
				System.out.println(result + "입금되었습니다.");
				break;
			case 2:
//				
				csmt = con.prepareCall("{ call withdraw(?, ?, ?) }");
				csmt.setString(1, inputValue("출금할 계좌번호"));
				csmt.setInt(2, Integer.parseInt(inputValue("출금할 금액")));
				csmt.registerOutParameter(3, Types.VARCHAR);
				csmt.execute();
				System.out.println("계좌 출금 결과:" + csmt.getString(3));
			}

		}
		catch (SQLException e) {
			e.printStackTrace();
		}
		finally {
			dbClose();
		}
		
	}
	
}
