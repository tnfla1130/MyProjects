import { useEffect, useState } from "react";

function AnnouncementBoard() { // 컴포넌트 이름 변경
  const [boards, setBoards] = useState([]);
  const [searchKeyword, setSearchKeyword] = useState("");
  const [selectedBoard, setSelectedBoard] = useState(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isCreating, setIsCreating] = useState(false);

  // 게시판 목록 가져오기 (공지사항 boardId=2)
  const fetchBoardList = async (keyword = "") => {
    try {
      const boardId = 2; // 공지사항 고정
      const baseUrl = `http://localhost:8080/api/board?boardId=${boardId}`;
      
      const url = keyword
        ? `${baseUrl}&searchField=board_title&searchKeyword=${encodeURIComponent(keyword)}`
        : baseUrl;

      console.log("fetch url:", url);

      const res = await fetch(url, {
        method: "GET",
        credentials: "include",
      });

      const data = await res.json();
      setBoards(Array.isArray(data) ? data : [data]);
    } catch (error) {
      console.error("Fetch error:", error);
    }
  };

  useEffect(() => {
    fetchBoardList(searchKeyword);
  }, [searchKeyword]);

  // 게시글 삭제
  const handleDelete = async (id) => {
    if (!window.confirm("정말 삭제하시겠습니까?")) return;
    try {
      const response = await fetch(
        `http://localhost:8080/api/board/delete/${id}`,
        { method: "DELETE", credentials: "include" }
      );
      if (response.ok) {
        alert("삭제 성공!");
        fetchBoardList(searchKeyword);
      } else {
        alert("삭제 실패!");
      }
    } catch (error) {
      console.error("삭제 중 오류 발생:", error);
    }
  };

  // 상세조회/수정 클릭
  const handleSelectBoard = (b) => {
    setSelectedBoard({ ...b });
    setIsCreating(false);
    setIsModalOpen(true);
  };

  // 생성 클릭
  const handleCreateClick = () => {
    setSelectedBoard({});
    setIsCreating(true);
    setIsModalOpen(true);
  };

  // 폼 변경
  const handleFormChange = (e) => {
    const { name, value } = e.target;
    setSelectedBoard({ ...selectedBoard, [name]: value });
  };

  // 검색 제출
  const handleSearchSubmit = (e) => {
    e.preventDefault();
    fetchBoardList(searchKeyword); // 항상 boardId=2 검색
  };

  // 폼 제출
  const handleFormSubmit = async (e) => {
    e.preventDefault();
    if (!selectedBoard) return;

    const boardData = {
      ...selectedBoard,
      boardId: 2, // 공지사항 고정
      boardDate: new Date().toISOString(),
      visitCount: selectedBoard.visitCount || 0,
    };

    try {
      if (isCreating) {
        await fetch("http://localhost:8080/api/board", {
          method: "POST",
          credentials: "include",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(boardData),
        });
        alert("게시글 생성 완료!");
      } else {
        if (!selectedBoard.boardIdx) {
          console.error("수정할 boardIdx가 없습니다.");
          return;
        }
        await fetch(
          `http://localhost:8080/api/board/edit/${selectedBoard.boardIdx}`,
          {
            method: "PUT",
            credentials: "include",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(boardData),
          }
        );
        alert("게시글 수정 완료!");
      }

      fetchBoardList(searchKeyword);
      setSelectedBoard(null);
      setIsCreating(false);
      setIsModalOpen(false);
    } catch (error) {
      console.error("오류 발생:", error);
    }
  };

  return (
    <div className="container-fluid">
      <h1 className="h3 mb-4 text-gray-800">공지사항 관리</h1>
      <button className="btn btn-primary mb-3" onClick={handleCreateClick}>
        게시글 생성
      </button>

      {/* 검색 폼 */}
      <form onSubmit={handleSearchSubmit} className="d-flex mb-3">
        <input
          type="text"
          className="form-control mr-2"
          placeholder="제목 검색"
          value={searchKeyword}
          style={{ width: "500px", padding: "5px" }}
          onChange={(e) => setSearchKeyword(e.target.value)}
        />
        <button type="submit" className="btn btn-secondary">
          검색
        </button>
      </form>

      {/* 게시판 목록 테이블 */}
      <table className="table table-bordered">
        <thead>
          <tr>
            <th>번호</th>
            <th>제목</th>
            <th>작성자</th>
            <th>등록일</th>
            <th>조회수</th>
            <th>관리</th>
          </tr>
        </thead>
        <tbody>
          {boards.map((b, i) => (
            <tr key={i}>
              <td>{b.boardIdx}</td>
              <td>{b.boardTitle}</td>
              <td>{b.writer}</td>
              <td>{b.boardDate}</td>
              <td>{b.visitCount}</td>
              <td>
                <button
                  className="btn btn-info btn-sm mr-2"
                  onClick={() => handleSelectBoard(b)}
                >
                  상세조회/수정
                </button>
                <button
                  className="btn btn-danger btn-sm"
                  onClick={() => handleDelete(b.boardIdx)}
                >
                  삭제
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      {/* 모달 */}
      {isModalOpen && (
        <div
          className="modal-backdrop"
          style={{
            position: "fixed",
            top: 0,
            left: 0,
            width: "100%",
            height: "100%",
            backgroundColor: "rgba(0,0,0,0.5)",
            display: "flex",
            justifyContent: "center",
            alignItems: "center",
            zIndex: 1000,
          }}
        >
          <div
            className="modal-content p-4 bg-white"
            style={{ width: "500px", borderRadius: "8px" }}
          >
            <h4>{isCreating ? "게시글 생성" : "게시글 수정 / 상세조회"}</h4>
            <form onSubmit={handleFormSubmit}>
              <input
                name="boardTitle"
                value={selectedBoard?.boardTitle || ""}
                onChange={handleFormChange}
                placeholder="제목"
                required
                className="form-control mb-2"
              />
              <textarea
                name="boardContent"
                value={selectedBoard?.boardContent || ""}
                onChange={handleFormChange}
                placeholder="내용"
                required
                className="form-control mb-2"
                rows={5}
              />
              <input
                name="writer"
                value={selectedBoard?.writer || ""}
                onChange={handleFormChange}
                placeholder="작성자"
                required
                className="form-control mb-2"
              />
              <button type="submit" className="btn btn-success">
                {isCreating ? "생성" : "수정"}
              </button>
              <button
                type="button"
                className="btn btn-secondary ml-2"
                onClick={() => setIsModalOpen(false)}
              >
                닫기
              </button>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

export default AnnouncementBoard;
