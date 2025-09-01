package banking.jdbc;


import java.io.IOException;
import java.io.Serializable;
import java.util.Scanner;

public class BankingSystemMain{
	
	public static Scanner scan = new Scanner(System.in);
	
	public static void showMenu() {
		System.out.println("===========================Menu============================");
		System.out.print("1.계좌개설");
		System.out.print(", 2.입  금/ 출  금");
		System.out.println(", 3.계좌정보출력");
		System.out.print(", 4.지정계좌정보출력");
		System.out.println(", 5.계좌정보삭제");
		System.out.println("===========================================================");
		System.out.print("메뉴선택>>>");
}
	public static void main(String[] args) {
		while(true) {
			showMenu();
			try {
				int choice = scan.nextInt();
				//입력버퍼에 남아있는 \n을 지움
				scan.nextLine();
				switch(choice) {
				case 1:
					//계좌개설
					new insertBank().dbExecute();
					break;
				case 2:
					//입금,출금
					new UpdateBank().dbExecute();
					break;
				case 3:
					//출금
					new AllSelectBank().dbExecute();
					break;
				case 4:
					//전체계좌 정보출력
					new SelectBank().dbExecute();
					break;
				case 5:
					//계좌정보삭제
					new deleteBank().dbExecute();
					break;
				
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


