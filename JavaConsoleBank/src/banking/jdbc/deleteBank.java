package banking.jdbc;

import java.sql.SQLException;
import java.sql.Types;

public class deleteBank extends MyConnection{
	
	public deleteBank() {
		super("education", "1234");
	}
	
	@Override
	public void dbExecute() {
		
		try {
			csmt = con.prepareCall("{ call DeleteAccount(?, ?) }");
			csmt.setString(1, inputValue("삭제할 계좌번호"));
			csmt.registerOutParameter(2, Types.VARCHAR);
			csmt.execute();
			System.out.println("계좌 삭제 결과:" + csmt.getString(2));
		}
		catch (SQLException e) {
			System.out.println("예외발생");
			e.printStackTrace();
		}
		finally {
			dbClose();
		}
		
	}

}
