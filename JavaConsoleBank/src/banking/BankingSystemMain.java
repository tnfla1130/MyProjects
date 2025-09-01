package banking;


import java.io.IOException;
import java.io.Serializable;
import java.util.Scanner;

public class BankingSystemMain{
	
	public static Scanner scan = new Scanner(System.in);
	
	public static void showMenu() {
		System.out.println("===========================Menu============================");
		System.out.print("1.계좌개설");
		System.out.print(", 2.입  금");
		System.out.print(", 3.출  금");
		System.out.println(", 4.계좌정보출력");
		System.out.print("5.계좌정보삭제");
		System.out.print(", 6.저장옵션");
		System.out.println(", 7.프로그램 종료");
		System.out.println("===========================================================");
		System.out.print("메뉴선택>>>");
}
	public static void main(String[] args) {
		AccountManager manager = new AccountManager(100);
		
		manager.LoadObject();
		while(true) {
			showMenu();
			try {
				int choice = scan.nextInt();
				//입력버퍼에 남아있는 \n을 지움
				scan.nextLine();
				switch(choice) {
				case 1:
					//계좌개설
					manager.makeAccount();
					break;
				case 2:
					//입금
					manager.depositMoney();;
					break;
				case 3:
					//출금
					manager.withdrawMoney();
					break;
				case 4:
					//전체계좌 정보출력
					manager.showAccInfo();
					break;
				case 5:
					//계좌정보삭제
					manager.deleteAccount();
					break;
				case 6:
					//자동저장
					manager.saver();
					break;
				case 7:
					//프로그램 종료
					manager.OutputObject();
					System.out.println("프로그램종료");
					return;
				default :
					System.out.println("메뉴입력 예외발생됨");
					System.out.println("메뉴는 1~5사이의 정수를 입력하세요.");
					break;
				}
			
			}
			catch ( Exception e) {
				System.out.println("[예외발생] 메뉴선택은 숫자만 입력해주세요");
				scan.nextLine();
			}
		}
	}

}


