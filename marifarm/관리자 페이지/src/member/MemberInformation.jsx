import { useEffect, useMemo, useRef, useState } from "react";

const API_BASE = "http://localhost:8080/api/member";

function MemberInformation() {
  const [member, setMember] = useState([]);
  const [searchKeyword, setSearchKeyword] = useState("");
  const [selectedMember, setSelectedMember] = useState(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isCreating, setIsCreating] = useState(false);
  const [loading, setLoading] = useState(false);
  const [errMsg, setErrMsg] = useState("");

  const debounceMs = 300;
  const debounceTimer = useRef(null);

  const listUrl = useMemo(() => `${API_BASE}`, []);
  const searchUrl = useMemo(
    () => (kw) => `${API_BASE}/search?keyword=${encodeURIComponent(kw)}`,
    []
  );

  const fetchMemberList = async (keyword = "") => {
    try {
      setLoading(true);
      setErrMsg("");

      const url =
        keyword && keyword.trim().length > 0
          ? searchUrl(keyword.trim())
          : listUrl;

      const res = await fetch(url, { method: "GET", credentials: "include" });
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data = await res.json();

      // /search는 없으면 [] 반환(백엔드에서 그렇게 구현)
      setMember(Array.isArray(data) ? data : [data].filter(Boolean));
    } catch (e) {
      console.error("Fetch error:", e);
      setErrMsg("목록/검색 조회 중 오류가 발생했습니다.");
      setMember([]);
    } finally {
      setLoading(false);
    }
  };

  // 최초 로딩
  useEffect(() => {
    fetchMemberList();
  }, []); // eslint-disable-line

  // 검색 폼 제출(버튼/Enter)
  const handleSearchSubmit = (e) => {
    e.preventDefault();
    // 즉시 호출 (디바운스 무시)
    if (debounceTimer.current) clearTimeout(debounceTimer.current);
    fetchMemberList(searchKeyword);
  };

  // 입력 시 디바운스 검색
  const handleSearchChange = (e) => {
    const kw = e.target.value;
    setSearchKeyword(kw);

    if (debounceTimer.current) clearTimeout(debounceTimer.current);
    debounceTimer.current = setTimeout(() => {
      fetchMemberList(kw);
    }, debounceMs);
  };

  // 삭제
  const handleDelete = async (id) => {
    if (!window.confirm("정말 삭제하시겠습니까?")) return;
    try {
      const response = await fetch(`${API_BASE}/deleteMember/${id}`, {
        method: "DELETE",
        credentials: "include",
      });
      if (response.ok) {
        alert("삭제 성공!");
        fetchMemberList(searchKeyword);
      } else {
        alert("삭제 실패!");
      }
    } catch (error) {
      console.error("삭제 중 오류 발생:", error);
    }
  };

  // 상세/수정 열기
  const handleSelectMember = (m) => {
    setSelectedMember({ ...m });
    setIsCreating(false);
    setIsModalOpen(true);
  };

  // 생성 열기
  const handleCreateClick = () => {
    setSelectedMember({});
    setIsCreating(true);
    setIsModalOpen(true);
  };

  // 폼 변경
  const handleFormChange = (e) => {
    const { name, value } = e.target;
    setSelectedMember((prev) => ({ ...prev, [name]: value }));
  };

  // 폼 제출 (생성/수정)
  const handleFormSubmit = async (e) => {
    e.preventDefault();
    if (!selectedMember) return;

    const basePayload = {
      userId: selectedMember.userId,
      password: selectedMember.password,
      email: selectedMember.email,
      domain: selectedMember.domain,
      nickname: selectedMember.nickname,
      phone: selectedMember.phone,
      memberAuth: selectedMember.memberAuth,
      gamePoint: Number(selectedMember.gamePoint ?? 0),
      gameExp: Number(selectedMember.gameExp ?? 0),
      gameLevel: Number(selectedMember.gameLevel ?? 1),
      gameImages: selectedMember.gameImages,
      address: selectedMember.address,
      detailAddress: selectedMember.detailAddress,
      postcode: Number(selectedMember.postcode ?? 0),
      // postdate 등 서버가 넣는 필드는 제외
    };

    try {
      if (isCreating) {
        const res = await fetch(`${API_BASE}`, {
          method: "POST",
          credentials: "include",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(basePayload),
        });
        if (!res.ok) throw new Error(`Create failed: HTTP ${res.status}`);
        alert("회원 생성 완료!");
      } else {
        if (!selectedMember.memberIdx) {
          console.error("수정할 memberIdx가 없습니다.");
          return;
        }
        const res = await fetch(
          `${API_BASE}/editMember/${selectedMember.memberIdx}`,
          {
            method: "PUT",
            credentials: "include",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(basePayload),
          }
        );
        if (!res.ok) throw new Error(`Update failed: HTTP ${res.status}`);
        alert("회원 정보 수정 완료!");
      }

      fetchMemberList(searchKeyword);
      setSelectedMember(null);
      setIsCreating(false);
      setIsModalOpen(false);
    } catch (error) {
      console.error("오류 발생:", error);
      alert("요청 처리 중 오류가 발생했습니다.");
    }
  };

  return (
    <div className="container-fluid">
      <h1 className="h3 mb-4 text-gray-800">회원 정보</h1>
      <button className="btn btn-primary mb-3" onClick={handleCreateClick}>
        회원 생성
      </button>

      {/* 검색 */}
      <form onSubmit={handleSearchSubmit} className="d-flex mb-3">
        <input
          type="text"
          className="form-control mr-2"
          placeholder="닉네임 또는 이메일 검색"
          value={searchKeyword}
          style={{ width: "500px", padding: "5px" }}
          onChange={handleSearchChange}
        />
        <button type="submit" className="btn btn-secondary">
          검색
        </button>
      </form>

      {/* 상태 표시 */}
      {loading && <div className="alert alert-info">로딩 중...</div>}
      {errMsg && <div className="alert alert-danger">{errMsg}</div>}
      {!loading && !errMsg && member.length === 0 && (
        <div className="alert alert-warning">검색 결과가 없습니다.</div>
      )}

      {/* 목록 */}
      <table className="table table-bordered">
        <thead>
          <tr>
            <th>ID</th>
            <th>닉네임</th>
            <th>이메일</th>
            <th>가입일자</th>
            <th>전화번호</th>
            <th>관리</th>
          </tr>
        </thead>
        <tbody>
          {member.map((m, i) => (
            <tr key={i}>
              <td>{m.memberIdx}</td>
              <td>{m.nickname}</td>
              <td>{m.email}</td>
              <td>{m.postdate}</td>
              <td>{m.phone}</td>
              <td>
                <button
                  className="btn btn-info btn-sm mr-2"
                  onClick={() => handleSelectMember(m)}
                >
                  상세조회/수정
                </button>
                <button
                  className="btn btn-danger btn-sm"
                  onClick={() => handleDelete(m.memberIdx)}
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
            <h4>{isCreating ? "회원 생성" : "회원 정보 수정 / 상세조회"}</h4>
            <form onSubmit={handleFormSubmit}>
              <input
                name="userId"
                value={selectedMember?.userId || ""}
                onChange={handleFormChange}
                placeholder="아이디"
                required
                className="form-control mb-2"
              />
              <input
                type="password"
                name="password"
                value={selectedMember?.password || ""}
                onChange={handleFormChange}
                placeholder="비밀번호"
                required
                className="form-control mb-2"
              />
              <input
                name="email"
                value={selectedMember?.email || ""}
                onChange={handleFormChange}
                placeholder="이메일"
                required
                className="form-control mb-2"
              />
              <input
                name="domain"
                value={selectedMember?.domain || ""}
                onChange={handleFormChange}
                placeholder="도메인"
                required
                className="form-control mb-2"
              />
              <input
                name="nickname"
                value={selectedMember?.nickname || ""}
                onChange={handleFormChange}
                placeholder="닉네임"
                required
                className="form-control mb-2"
              />
              <input
                name="phone"
                value={selectedMember?.phone || ""}
                onChange={handleFormChange}
                placeholder="전화번호"
                required
                className="form-control mb-2"
              />
              <input
                name="memberAuth"
                value={selectedMember?.memberAuth || ""}
                onChange={handleFormChange}
                placeholder="권한 (ROLE_USER/ROLE_ADMIN)"
                required
                className="form-control mb-2"
              />
              <input
                type="number"
                name="gamePoint"
                value={selectedMember?.gamePoint ?? 0}
                onChange={handleFormChange}
                placeholder="게임 포인트"
                className="form-control mb-2"
              />
              <input
                type="number"
                name="gameExp"
                value={selectedMember?.gameExp ?? 0}
                onChange={handleFormChange}
                placeholder="게임 경험치"
                className="form-control mb-2"
              />
              <input
                type="number"
                name="gameLevel"
                value={selectedMember?.gameLevel ?? 1}
                onChange={handleFormChange}
                placeholder="게임 레벨"
                className="form-control mb-2"
              />
              <input
                name="gameImages"
                value={selectedMember?.gameImages || ""}
                onChange={handleFormChange}
                placeholder="아바타/캐릭터 이미지"
                className="form-control mb-2"
              />
              <input
                name="address"
                value={selectedMember?.address || ""}
                onChange={handleFormChange}
                placeholder="주소"
                required
                className="form-control mb-2"
              />
              <input
                name="detailAddress"
                value={selectedMember?.detailAddress || ""}
                onChange={handleFormChange}
                placeholder="상세주소"
                required
                className="form-control mb-2"
              />
              <input
                type="number"
                name="postcode"
                value={selectedMember?.postcode ?? ""}
                onChange={handleFormChange}
                placeholder="우편번호"
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

export default MemberInformation;
