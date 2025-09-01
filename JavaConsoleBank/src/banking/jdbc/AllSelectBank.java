package banking.jdbc;

import java.sql.SQLException;
import java.sql.Types;

public class AllSelectBank extends MyConnection{

	public AllSelectBank() {
		super("education", "1234");
	}
	@Override
	public void dbExecute() {
		
		try {
//			String scan = inputValue("전체계좌정보출력");
			stmt = con.createStatement();
			String query = "select id, accNum, name, balnc, rate "
					+ "from banking";
			rs = stmt.executeQuery(query);
			
			while(rs.next()) {
				String id = rs.getString(1);
				String accNum = rs.getString("accNum");
				String name = rs.getString("name");
				int balnc = rs.getInt("balnc");
				int rate = rs.getInt("rate");
				
				System.out.printf("%s %s %s %d %d%%\n", id, accNum, name, balnc, rate);
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
