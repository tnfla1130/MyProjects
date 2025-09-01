package banking.jdbc;

import java.sql.SQLException;

public class insertBank extends MyConnection{

	public insertBank() {
		super("education", "1234");
	}
	
	String query;
	int result;
	
	@Override
	public void dbExecute() {
		
		try {
			query = "insert into banking (id, accNum, name, balnc, rate) values "
					+ "(?, ?, ?, ?, ?)";
			psmt = con.prepareStatement(query);
			psmt.setString(1, inputValue("일련번호"));
			psmt.setString(2, inputValue("계좌번호"));
			psmt.setString(3, inputValue("이름"));
			psmt.setInt(4, Integer.parseInt(inputValue("잔액")));
			psmt.setInt(5, Integer.parseInt(inputValue("이자율")));
			
			result = psmt.executeUpdate();
			System.out.println(result + "계좌 개설");
			
		}
		catch (SQLException e) {
			e.printStackTrace();
		}
		finally {
			dbClose();
		}
		
	}
	

}
