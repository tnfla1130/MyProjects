package banking.threeby3;

import java.util.Random;
import java.util.Scanner;

public class ThreeByGame {

	int randomCnt = 50;
	Random random = new Random();
	char[][] arr = {
		{'1','2','3'},
		{'4','5','6'},
		{'7','8','X'}
	};
	private final char[][] goal = {
		    {'1','2','3'},
		    {'4','5','6'},
		    {'7','8','X'}
		};
	
	int x = 2; 
	int y = 2;
	public void suffleGame() {
		int[][] directions = {
				{-1, 0}, // 위
				{1, 0},  // 아래
				{0, -1}, // 왼쪽
				{0, 1}   // 오른쪽
		};
	    for (int i=0; i<randomCnt ; i++) {
            int dir = random.nextInt(10000);
            int rand_dir = dir%4;
            int newX = x + directions[rand_dir][0];
            int newY = y + directions[rand_dir][1];

            if (newX >= 0 && newX < 3 && newY >= 0 && newY < 3) {
                // 값 스왑
                char temp = arr[x][y];
                arr[x][y] = arr[newX][newY];
                arr[newX][newY] = temp;
                x = newX;
                y = newY;
            }
        }
	    resultBoard();
	    
	}
	public static Scanner scan = new Scanner(System.in);
	
	public void beginGame() {
		System.out.println("게임을 시작합니다! ");
		while(true) {
			System.out.println("(W: 위, A: 왼쪽, S: 아래, D: 오른쪽, Q: 종료)");
			int newX = x, newY = y;
			char choice = scan.next().charAt(0);
			switch(choice) {
			case 'w': newX = x - 1; break;
			case 's': newX = x + 1; break;
			case 'a': newY = y - 1; break;
			case 'd': newY = y + 1; break;
			case 'q': System.out.println("게임 종료"); return;
			default:
				System.out.println("잘못된 입력입니다.");
				continue;
			}
			if (newX >= 0 && newX < 3 && newY >= 0 && newY < 3) {
				swap(x, y, newX, newY);
				x = newX;
				y = newY;
				resultBoard();
			} else {
				System.out.println("이동할 수 없습니다.");
			}
			if (isGoal()) {
	            System.out.println("퍼즐을 완성했습니다! 게임을 종료합니다.");
	            if (askRetry()) break; // break 내부 루프 → 다시 시작
                else return;
			}
		}
		resetGame();
	}
	private boolean isGoal() {
	    for (int i = 0; i < 3; i++) {
	        for (int j = 0; j < 3; j++) {
	            if (arr[i][j] != goal[i][j]) return false;
	        }
	    }
	    return true;
	}
	private void swap(int x1, int y1, int x2, int y2) {
        char temp = arr[x1][y1];
        arr[x1][y1] = arr[x2][y2];
        arr[x2][y2] = temp;
    }
	private void resultBoard() {
        System.out.println("현재 퍼즐 상태:");
        for (char[] row : arr) {
            for (char c : row) {
                System.out.print(c + " ");
            }
            System.out.println();
        }
	}
	private void resetGame() {
	    arr = new char[][]{
	        {'1','2','3'},
	        {'4','5','6'},
	        {'7','8','X'}
	    };
	    x = 2;
	    y = 2;
	    start();
	}
	// 재시작 여부 확인
	private boolean askRetry() {
	    System.out.print("게임을 다시 시작하시겠습니까? (Y/N): ");
	    char retry = scan.next().toLowerCase().charAt(0);
	    return retry == 'y';
	}
	public void start() {
		
		suffleGame();
		beginGame();
	}
	public static void main(String[] args) {
		ThreeByGame game = new ThreeByGame();
		game.start();
		
	}
}




































