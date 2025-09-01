package banking;

import java.io.PrintWriter;
import java.io.Serializable;

public abstract class Account implements Serializable {
	
	private String acc_num;
	private String name;
	private int balnc;
	
	//생성자
	public Account(String acc_num, String name, int balnc) {
		this.acc_num = acc_num;
		this.name = name;
		this.balnc = balnc;
	}
	
	public String getAcc_num() {
		return acc_num;
	}
	public String getName() {
		return name;
	}

	public int getBalnc() {
		return balnc;
	}
	public void setBalnc(int balnc) {
		this.balnc = balnc;
	}
	
	@Override
	public boolean equals(Object obj) {
		Account ac = (Account) obj;
		if (this.acc_num.equals(ac.acc_num)) return true;
		else return false;
	}
	@Override
	public int hashCode() {
	    return getAcc_num().hashCode();
	}
	public void printAcc(PrintWriter out) {
		out.println("----------------------");
		out.println("계좌번호 : "+acc_num);
		out.println("고객이름 : "+ name);
		out.println("잔고 : "+ balnc);
	}
	
	public void showAccInfo() {
		System.out.println("계좌번호 : "+acc_num);
		System.out.println("고객이름 : "+ name);
		System.out.println("잔고 : "+ balnc);
	}
	
	public void deposit(Account account, int money, int deposit) {
		
	}
	
}
