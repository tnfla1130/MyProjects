package banking;

import java.io.PrintWriter;

public class NormalAccount extends Account{

	private int baseRate;
	int money, deposit;
	
	public NormalAccount(String acc_num, String name, int balnc, int baseRate) {
		super(acc_num, name, balnc);
		this.baseRate = baseRate;
	}
	public int getBaseRate() {
		return baseRate;
	}
	@Override
	public void printAcc(PrintWriter out) {
		super.printAcc(out);
		out.println("기본이자 : "+ baseRate+ "%");
		out.println("----------------------");
	}
	
	@Override
	public void showAccInfo() {
		System.out.println("----------------------");
		System.out.println("보통계좌");
		super.showAccInfo();
		System.out.println("기본이자 : "+ baseRate+ "%");
		
	}
	
	
	@Override
	public void deposit(Account account, int money, int deposit) {
		int cal_rate =  (int)Math.floor(money + ( money * getBaseRate()/100 ) 
				+ deposit);
		account.setBalnc(cal_rate);
		System.out.println("NormalAccount");
		System.out.println("입금이 완료되었습니다.");
	}

	
}
