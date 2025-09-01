package banking;

import java.io.PrintWriter;

public class HighCreditAccount extends Account{

	private int baseRate;
	int money, deposit;
	private char grade;
	int cal=0;
	
	public HighCreditAccount(String acc_num, String name, int balnc, 
				int baseRate , char grade) {
		super(acc_num, name, balnc);
		this.baseRate = baseRate;
		this.grade = grade;
	}
	
	public int getBaseRate() {
		return baseRate;
	}
	public char getGrade() {
		return grade;
	}
	public void setGrade(char grade) {
		this.grade = grade;
	}
	@Override
	public void printAcc(PrintWriter out) {
		super.printAcc(out);
		out.println("기본이자 : "+ baseRate+ "%");
		out.println("신용등급 : " + grade);
		out.println("----------------------");
	}
	
	@Override
	public void showAccInfo() {
		System.out.println("----------------------");
		System.out.println("신용신뢰계좌");
		super.showAccInfo();
		System.out.println("기본이자 : "+ baseRate+ "%");
		System.out.println("신용등급 : " + grade);

		
	}
	@Override
	public void deposit(Account account, int money, int deposit) {
		switch(grade) {
		case 'A':
		case 'a':
			cal = (int)Math.floor(money + ( money * baseRate/100 ) + 
					(money * 0.07) + deposit);
			break;
		case 'B':
		case 'b':
			cal = (int)Math.floor(money + ( money * baseRate/100 ) + 
					(money * 0.04) + deposit);
			break;
		
		case 'C':
		case 'c':
			cal = (int)Math.floor(money + ( money * baseRate/100 ) + 
					(money * 0.02) + deposit);
			break;
		default:
			cal=money;
			break;
		}	
		account.setBalnc(cal);
		System.out.println("HighCreditAccount");
		System.out.println("입금이 완료되었습니다.");
	}
	
}
