package banking;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.util.HashSet;

public class AccountManager {
	
	//정보 카운트용 변수 생성 
	private int numAcc;
	
	int depositNum=0;
	private HashSet<Account> acc = new HashSet<>();
	//생성자 
	public AccountManager(int num) {
		acc = new HashSet<Account>();	
		//카운트용 변수는 0으로 초기화 
	}
	public HashSet<Account> getAccounts() {
        return acc; // 주의: 원본을 넘기는 거라 복사본이 필요할 수 있음
    }
 
	public void makeAccount() {
		int choice;
		int returnNum=0;
		String acc_num, name;
		int balnc, rate;
		char grade;
		Account accountToAdd = null;
		System.out.println();
		System.out.println("***신규계좌개설***");
		System.out.println("-----계좌선택------");
		System.out.print("1.보통계좌");
		System.out.print(", 2.특판계좌");
		System.out.println(", 3.신용신뢰계좌");
		System.out.print("메뉴선택>>>");
		
		choice = BankingSystemMain.scan.nextInt();
		BankingSystemMain.scan.nextLine();
		
		System.out.print("계좌번호 : ");
		acc_num = BankingSystemMain.scan.nextLine();
		System.out.print("이름 : ");
		name = BankingSystemMain.scan.nextLine();
		System.out.print("잔고 : ");
		balnc = BankingSystemMain.scan.nextInt();
		System.out.print("기본이자%(정수형태로입력):"); 
		rate = BankingSystemMain.scan.nextInt();
		BankingSystemMain.scan.nextLine(); 
		
		switch(choice) {
		case 1:
			accountToAdd = new NormalAccount(acc_num, name, balnc, rate);
			break;
		case 2:
			accountToAdd = new SpecialAccount(acc_num, name, balnc, rate);
			break;
		case 3 :
			System.out.print("신용등급(A,B,C등급):"); 
			grade = BankingSystemMain.scan.next().charAt(0);
			if (grade != 'A' && grade != 'a' &&
		        grade != 'B' && grade != 'b' &&
		        grade != 'C' && grade != 'c') {
			        System.out.println("잘못된 신용등급입니다. A, B, C 중 하나만 입력하세요.");
			        return;
			    }
			accountToAdd = 
					new HighCreditAccount(acc_num, name, balnc, rate, grade);
			BankingSystemMain.scan.nextLine();
			break;
		default : 
			System.out.println("잘못된 선택입니다.");
			return;
		}
		if (acc.add(accountToAdd)) {
	        System.out.println("계좌개설이 완료되었습니다.");
	    } 
		else {
	        returnNum = 1;
	    }
		if (returnNum == 1) {
			System.out.print("중복 계좌번호입니다. 덮어쓸까요?(Y/N)");
			choice = BankingSystemMain.scan.next().charAt(0);
			BankingSystemMain.scan.nextLine();
			if (choice == 'Y' || choice == 'y') {
	            acc.remove(accountToAdd);
	            acc.add(accountToAdd);
	            System.out.println("기존정보에 덮어쓰기 하였습니다.");
	        } 
			else if(choice == 'N' || choice == 'n'){
	            System.out.println("새로운 정보가 지워졌습니다.");
			}
			else {
				System.out.println("잘못된 선택입니다.");
			}
		}
	}
	
	public void showAccInfo() {
		for(Account account : acc) {
			account.showAccInfo();
		}
		System.out.println("----------------------");
		System.out.println("전체계좌정보 출력이 완료되었습니다.");
	}
	
	public void depositMoney() {
		String accNum;
		int Money;
		System.out.println("***입  금***");
		System.out.println("계좌번호와 입금할 금액을 입력하세요.");
		System.out.print("계좌번호 : ");
		accNum = BankingSystemMain.scan.nextLine();
		System.out.print("입금액 : ");
		Money = BankingSystemMain.scan.nextInt();
		BankingSystemMain.scan.nextLine();
		if(Money>=0 && Money%500==0) {
			for(Account account : acc) {
				if (account == null) continue;
				if(accNum.equals(account.getAcc_num())) {
					
					if (account instanceof SpecialAccount) {
						account.deposit(account, account.getBalnc(), Money);
					}
					
					else if (account instanceof HighCreditAccount) {
						account.deposit(account,account.getBalnc(), Money);
					}
					else if(account instanceof NormalAccount) {
						account.deposit(account, account.getBalnc(), Money);
					}
				}
			}
		}
		else if(Money<0) {
			System.out.println("음수를 입금할 수 없습니다.");
		}
		else if(Money%500 != 0) {
			System.out.println("500원 단위로만 입금이 가능합니다.");
		}
		else {
			System.out.println("금액 입력시 문자를 입력할 수 없습니다.");
		}
	}
	
	public void withdrawMoney() {
		String accNum;
		int Money;
		char choice;
		System.out.println("***출  금***");
		System.out.println("계좌번호와 출금할 금액을 입력하세요.");
		System.out.print("계좌번호 : ");
		accNum = BankingSystemMain.scan.nextLine();
		System.out.print("출금액 : ");
		Money = BankingSystemMain.scan.nextInt();
		
		if (Money > 0 && Money%1000==0) {
			for(Account account : acc) {
				if(accNum.compareTo(account.getAcc_num())==0) {
					if(account.getBalnc() >= Money) {
						account.setBalnc(account.getBalnc() - Money);			
						System.out.println("출금이 완료되었습니다.");
					}
					else if (account.getBalnc() < Money){
						System.out.println("잔고가 부족합니다. 금액전체를 출금할까요?(Y/N)");
						choice = BankingSystemMain.scan.next().charAt(0);
						BankingSystemMain.scan.nextLine();
						switch(choice) {
						case 'Y','y':
							account.setBalnc(0);
							System.out.println("금액전체 출금처리가 완료되었습니다.");
							break;
						case 'N','n':
							System.out.println("출금요청이 취소되었습니다.");
							break;
						}
						
					}
					else {
						System.out.println("정확히 입력해주세요.");
					}
				}
			}
		}
		else if (Money < 0) {
			System.out.println("음수를 출금할 수 없습니다.");
		}
		else if(Money%1000!=0) {
			System.out.println("1000원 단위로만 입금이 가능합니다.");
		}
	}
	public void deleteAccount() {
		System.out.print("삭제할 계좌을 입력하세요:");
		String delete = BankingSystemMain.scan.nextLine();
		int deleteIndex = -1; 
		
		for(Account account : acc) {
			if(delete.equals(account.getAcc_num())) {
				acc.remove(account);
				deleteIndex = 0;
				break;
			}
		}
		if(deleteIndex==-1) {
			System.out.println("##삭제된 데이터가 없습니다##");
		}
		else {
			System.out.println("##삭제되었습니다##");
		}
	}
	public void OutputObject() {
		try {
			ObjectOutputStream out =
					new ObjectOutputStream(
							new FileOutputStream("src/banking/AccountInfo.obj"));
			
			out.writeObject(acc);
			
			out.close();
			System.out.println("AccountInfo.obj 로 저장되었습니다.");
			
		}
		catch(IOException e) {
			System.out.println("입출력 오류");
			System.out.println(e.getMessage());
		}
	}
	public void LoadObject() {
		try {
			ObjectInputStream in =
					new ObjectInputStream(
							new FileInputStream("src/banking/AccountInfo.obj"));
			
			this.acc = (HashSet<Account>) in.readObject();
			
			in.close();
			System.out.println("AccountInfo.obj 를 불러옵니다. 총 계좌 수:"+ acc.size());
		}
		catch (IOException e) {
			System.out.println("예외발생");
		} 
		catch (ClassNotFoundException e) {
			e.printStackTrace();
		}
		
	}
	public void saver() {
		
		int choice2;
		AutoSaver as = new AutoSaver(this);
		System.out.println("1. 자동저장On, 2. 자동저장Off");
		System.out.print(">>>");
		choice2 = BankingSystemMain.scan.nextInt();
		BankingSystemMain.scan.nextLine();
		as.setDaemon(true);
		switch(choice2) {
		case 1:
			if (as.isAlive()) {
				System.out.println("이미 자동저장이 실행중입니다.");
			}
			else {
				as.start();
				System.out.println("자동저장 ON");
			}
			break;
		case 2:
			as.interrupt();
			System.out.println("자동저장 OFF");
			break;
		}
	}
}



























