// UserGameAdmin.jsx
import { useEffect, useState } from "react";

/** ===== API 엔드포인트 ===== */
const API_HOST = "http://localhost:8080";
const ENDPOINTS = {
  list: (page = 0, size = 50) => `${API_HOST}/api/admin/member?page=${page}&size=${size}`,
  search: ({ q = "", page = 0, size = 50, userId, nickname, email } = {}) => {
    const params = new URLSearchParams();
    params.set("page", page);
    params.set("size", size);
    if (q && q.trim()) params.set("q", q.trim());
    if (userId && userId.trim()) params.set("userId", userId.trim());
    if (nickname && nickname.trim()) params.set("nickname", nickname.trim());
    if (email && email.trim()) params.set("email", email.trim());
    return `${API_HOST}/api/admin/member?${params.toString()}`;
  },
  getOne: (memberIdx) => `${API_HOST}/api/admin/member/${memberIdx}`,
  update: (memberIdx) => `${API_HOST}/api/admin/member/${memberIdx}`,
};

/** ===== 유틸 ===== */
function formatDate(d) {
  if (!d) return "";
  const date = new Date(d);
  if (Number.isNaN(date.getTime())) return String(d);
  return new Intl.DateTimeFormat(undefined, {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  }).format(date);
}

const getToken = () => localStorage.getItem("token");
const buildHeaders = (json = false) => {
  const h = {
    Accept: "application/json",
    "X-Requested-With": "XMLHttpRequest",
  };
  const t = getToken();
  if (t) h.Authorization = `Bearer ${t}`;
  if (json) h["Content-Type"] = "application/json";
  return h;
};

async function parseJSONSafe(res) {
  const ct = res.headers.get("content-type") || "";
  if (res.status === 204) return null;
  if (!ct.includes("application/json")) {
    const text = await res.text();
    throw new Error(`Non-JSON response (${res.status}): ${text.slice(0, 160)}...`);
  }
  return res.json();
}

/** ===== 메인 컴포넌트 ===== */
export default function UserGameAdmin() {
  const [rows, setRows] = useState([]);
  const [pageInfo, setPageInfo] = useState({
    number: 0,
    size: 50,
    totalPages: 1,
    totalElements: 0,
  });

  // 검색 스테이트
  const [q, setQ] = useState(""); // 자유 검색어
  const [userId, setUserId] = useState("");
  const [nickname, setNickname] = useState("");
  const [email, setEmail] = useState("");

  // 상세/수정 모달
  const [selected, setSelected] = useState(null);
  const [isModalOpen, setIsModalOpen] = useState(false);

  // 상태
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");

  /** 목록/검색 조회 */
  const fetchList = async (opts = {}) => {
    const { page = 0, size = pageInfo.size } = opts;
    setIsLoading(true);
    setError("");
    try {
      const hasAnyFilter =
        (q && q.trim()) ||
        (userId && userId.trim()) ||
        (nickname && nickname.trim()) ||
        (email && email.trim());

      const url = hasAnyFilter
        ? ENDPOINTS.search({
            q,
            userId,
            nickname,
            email,
            page,
            size,
          })
        : ENDPOINTS.list(page, size);

      const res = await fetch(url, {
        method: "GET",
        credentials: "include",
        headers: buildHeaders(false),
      });
      if (!res.ok) {
        const text = await res.text().catch(() => "");
        throw new Error(`HTTP ${res.status}: ${text.slice(0, 160)}...`);
      }
      const data = await parseJSONSafe(res);

      // Page 응답 또는 배열 대응
      const list = Array.isArray(data) ? data : data?.content ?? [];
      setRows(list);

      if (!Array.isArray(data) && data) {
        setPageInfo({
          number: data.number ?? page,
          size: data.size ?? size,
          totalPages: data.totalPages ?? 1,
          totalElements: data.totalElements ?? list.length,
        });
      } else {
        setPageInfo({ number: 0, size, totalPages: 1, totalElements: list.length });
      }
    } catch (e) {
      setError(e.message || String(e));
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchList({ page: 0 });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  /** 상세 조회 후 모달 오픈 (보수적으로 서버에서 한번 더 읽기) */
  const handleSelect = async (row) => {
    try {
      const res = await fetch(ENDPOINTS.getOne(row.memberIdx), {
        method: "GET",
        credentials: "include",
        headers: buildHeaders(false),
      });
      if (!res.ok) {
        const text = await res.text().catch(() => "");
        throw new Error(`HTTP ${res.status}: ${text.slice(0, 160)}...`);
      }
      const data = await parseJSONSafe(res);
      // 필요한 필드만 보존 (직렬화 이슈 대비)
      const pick = (m) => ({
        memberIdx: m.memberIdx,
        userId: m.userId,
        nickname: m.nickname,
        email: m.email,
        gamePoint: m.gamePoint ?? 0,
        gameExp: m.gameExp ?? 0,
        gameLevel: m.gameLevel ?? 1,
        emailVerified: m.emailVerified, // 'Y'/'N'일 수 있음
        updatedAt: m.updatedAt || m.modifiedAt || m.updated_at,
      });
      setSelected(pick(data || row));
      setIsModalOpen(true);
    } catch (e) {
      alert(e.message || "상세 조회 중 오류가 발생했습니다.");
    }
  };

  /** 폼 변경 */
  const handleFormChange = (e) => {
    const { name, value } = e.target;
    if (!selected) return;
    if (["gamePoint", "gameExp", "gameLevel"].includes(name)) {
      const num = Number(value);
      setSelected((p) => ({ ...p, [name]: Number.isNaN(num) ? "" : num }));
    } else {
      setSelected((p) => ({ ...p, [name]: value }));
    }
  };

  /** 저장(수정) */
  const handleFormSubmit = async (e) => {
    e.preventDefault();
    if (!selected) return;

    // 숫자 검증
    const gp = Number(selected.gamePoint);
    const ge = Number(selected.gameExp);
    const gl = Number(selected.gameLevel);
    if ([gp, ge, gl].some((v) => Number.isNaN(v))) {
      alert("코인/경험치/레벨은 숫자여야 합니다.");
      return;
    }

    // NOTE: 백엔드가 Long을 받으므로 JS Number로 보내면 OK
    const payload = {
      gamePoint: gp,
      gameExp: ge,
      gameLevel: gl,
    };

    try {
      const res = await fetch(ENDPOINTS.update(selected.memberIdx), {
        method: "PUT",
        credentials: "include",
        headers: buildHeaders(true),
        body: JSON.stringify(payload),
      });
      if (!res.ok) {
        const text = await res.text().catch(() => "");
        throw new Error(`HTTP ${res.status}: ${text.slice(0, 200)}...`);
      }
      await parseJSONSafe(res);
      alert("저장 완료!");
      setIsModalOpen(false);
      setSelected(null);
      fetchList({ page: pageInfo.number });
    } catch (err) {
      alert(err.message || "저장 중 오류가 발생했습니다.");
    }
  };

  /** 검색 제출 */
  const handleSearchSubmit = (e) => {
    e.preventDefault();
    fetchList({ page: 0 });
  };

  /** 페이지 이동 */
  const prevPage = () => {
    if (pageInfo.number <= 0) return;
    fetchList({ page: pageInfo.number - 1 });
  };
  const nextPage = () => {
    if (pageInfo.number + 1 >= pageInfo.totalPages) return;
    fetchList({ page: pageInfo.number + 1 });
  };

  return (
    <div className="container-fluid">
      <h1 className="h3 mb-4 text-gray-800">회원 게임 정보 관리</h1>

      {/* 검색 바 */}
      <form onSubmit={handleSearchSubmit} className="d-flex align-items-end mb-3" style={{ gap: 8, flexWrap: "wrap" }}>
        <div>
          <label className="form-label">키워드(q)</label>
          <input
            type="text"
            className="form-control"
            placeholder="userId / nickname / email"
            value={q}
            onChange={(e) => setQ(e.target.value)}
            style={{ width: 240 }}
          />
        </div>
        <div>
          <label className="form-label">userId</label>
          <input
            type="text"
            className="form-control"
            placeholder="정확히 일치 검색(옵션)"
            value={userId}
            onChange={(e) => setUserId(e.target.value)}
            style={{ width: 180 }}
          />
        </div>
        <div>
          <label className="form-label">nickname</label>
          <input
            type="text"
            className="form-control"
            placeholder="포함 검색(옵션)"
            value={nickname}
            onChange={(e) => setNickname(e.target.value)}
            style={{ width: 180 }}
          />
        </div>
        <div>
          <label className="form-label">email</label>
          <input
            type="text"
            className="form-control"
            placeholder="포함 검색(옵션)"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            style={{ width: 220 }}
          />
        </div>
        <button type="submit" className="btn btn-secondary" style={{ height: 38 }}>
          검색
        </button>
      </form>

      {isLoading && <div className="alert alert-info">불러오는 중...</div>}
      {error && <div className="alert alert-danger">{error}</div>}

      {/* 목록 */}
      <table className="table table-bordered">
        <thead>
          <tr>
            <th style={{ width: 100 }}>memberIdx</th>
            <th style={{ width: 140 }}>userId</th>
            <th style={{ width: 160 }}>nickname</th>
            <th style={{ width: 220 }}>email</th>
            <th style={{ width: 120, textAlign: "right" }}>gamePoint</th>
            <th style={{ width: 120, textAlign: "right" }}>gameExp</th>
            <th style={{ width: 120, textAlign: "right" }}>gameLevel</th>
            <th style={{ width: 160 }}>업데이트</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((r) => (
            <tr key={r.memberIdx}>
              <td>{r.memberIdx}</td>
              <td>{r.userId}</td>
              <td>{r.nickname}</td>
              <td>{r.email}</td>
              <td style={{ textAlign: "right" }}>{r.gamePoint}</td>
              <td style={{ textAlign: "right" }}>{r.gameExp}</td>
              <td style={{ textAlign: "right" }}>{r.gameLevel}</td>
              <td>
                <button className="btn btn-info btn-sm" onClick={() => handleSelect(r)}>
                  상세/수정
                </button>
              </td>
            </tr>
          ))}
          {rows.length === 0 && !isLoading && (
            <tr>
              <td colSpan={8} className="text-center text-muted">
                데이터가 없습니다.
              </td>
            </tr>
          )}
        </tbody>
      </table>

      {/* 페이지네이션 */}
      <div className="d-flex align-items-center justify-content-between mb-3">
        <div>
          총 {pageInfo.totalElements}건 / {pageInfo.number + 1} / {pageInfo.totalPages} 페이지
        </div>
        <div style={{ display: "flex", gap: 8 }}>
          <button className="btn btn-outline-secondary btn-sm" disabled={pageInfo.number <= 0} onClick={prevPage}>
            이전
          </button>
          <button
            className="btn btn-outline-secondary btn-sm"
            disabled={pageInfo.number + 1 >= pageInfo.totalPages}
            onClick={nextPage}
          >
            다음
          </button>
        </div>
      </div>

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
          <div className="modal-content p-4 bg-white" style={{ width: 560, borderRadius: 8 }}>
            <h4>회원 정보 수정 (memberIdx: {selected?.memberIdx})</h4>
            <form onSubmit={handleFormSubmit}>
              <div className="d-flex" style={{ gap: 8 }}>
                <div className="flex-fill">
                  <label className="form-label">userId</label>
                  <input
                    type="text"
                    className="form-control mb-2"
                    value={selected?.userId ?? ""}
                    disabled
                    readOnly
                  />
                </div>
                <div className="flex-fill">
                  <label className="form-label">nickname</label>
                  <input
                    type="text"
                    name="nickname"
                    className="form-control mb-2"
                    value={selected?.nickname ?? ""}
                    onChange={handleFormChange}
                    disabled
                  />
                </div>
              </div>

              <div className="d-flex" style={{ gap: 8 }}>
                <div className="flex-fill">
                  <label className="form-label">gamePoint</label>
                  <input
                    type="number"
                    name="gamePoint"
                    className="form-control mb-2"
                    value={selected?.gamePoint ?? ""}
                    onChange={handleFormChange}
                    min={0}
                    required
                  />
                </div>
                <div className="flex-fill">
                  <label className="form-label">gameExp</label>
                  <input
                    type="number"
                    name="gameExp"
                    className="form-control mb-2"
                    value={selected?.gameExp ?? ""}
                    onChange={handleFormChange}
                    min={0}
                    required
                  />
                </div>
                <div className="flex-fill">
                  <label className="form-label">gameLevel</label>
                  <input
                    type="number"
                    name="gameLevel"
                    className="form-control mb-2"
                    value={selected?.gameLevel ?? ""}
                    onChange={handleFormChange}
                    min={1}
                    required
                  />
                </div>
              </div>

              <div className="text-muted mb-2">최근 수정: {formatDate(selected?.updatedAt)}</div>

              <button type="submit" className="btn btn-success">저장</button>
              <button type="button" className="btn btn-secondary ml-2" onClick={() => setIsModalOpen(false)}>
                닫기
              </button>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
