package banking.jdbc;

import java.sql.SQLException;
import java.sql.Types;

public class SelectBank extends MyConnection{

	public SelectBank() {
		super("education", "1234");
	}
	@Override
	public void dbExecute() {
		
		try {
			String scan = inputValue("검색하고 싶은 계좌번호를 입력하세요.");
			stmt = con.createStatement();
			String query = "select id, accNum, name, balnc, rate "
					+ "from banking "
					+ "where accNum="+ scan;
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
