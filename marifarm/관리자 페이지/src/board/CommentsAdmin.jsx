// CommentsAdmin.jsx
import { useEffect, useState } from "react";

/** ===== API 엔드포인트 ===== */
const API_HOST = "http://localhost:8080";
const ENDPOINTS = {
  list: (page = 0, size = 50) => `${API_HOST}/api/admin/comments?page=${page}&size=${size}`,
  search: ({ q = "", page = 0, size = 50, writer, commentId, from, to } = {}) => {
    const params = new URLSearchParams();
    params.set("page", page);
    params.set("size", size);
    if (q && q.trim()) params.set("q", q.trim());
    if (writer && writer.trim()) params.set("writer", writer.trim());
    if (commentId) params.set("commentId", commentId);
    if (from) params.set("from", from); // YYYY-MM-DD
    if (to) params.set("to", to);       // YYYY-MM-DD
    return `${API_HOST}/api/admin/comments?${params.toString()}`;
  },
  create: () => `${API_HOST}/api/admin/comments`,
  update: (idx) => `${API_HOST}/api/admin/comments/${idx}`,
  remove: (idx) => `${API_HOST}/api/admin/comments/${idx}`,
};

/** ===== 유틸 ===== */
function formatDate(d) {
  if (!d) return "";
  const date = new Date(d);
  if (Number.isNaN(date.getTime())) return String(d);
  return new Intl.DateTimeFormat(undefined, {
    year: "numeric", month: "2-digit", day: "2-digit",
    hour: "2-digit", minute: "2-digit",
  }).format(date);
}

// 인증 헤더
const getToken = () => localStorage.getItem("token"); // 프로젝트 저장소 규약에 맞게 조정 가능
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

// 안전한 JSON 파서
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
export default function CommentsAdmin() {
  const [rows, setRows] = useState([]);
  const [pageInfo, setPageInfo] = useState({ number: 0, size: 50, totalPages: 1, totalElements: 0 });

  const [q, setQ] = useState("");               // 내용 검색
  const [writer, setWriter] = useState("");     // 작성자 검색(선택)
  const [commentId, setCommentId] = useState(""); // 게시물ID(선택)
  const [from, setFrom] = useState(""); // YYYY-MM-DD
  const [to, setTo] = useState("");     // YYYY-MM-DD

  const [selected, setSelected] = useState(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isCreating, setIsCreating] = useState(false);

  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");

  /** 목록/검색 조회 */
  const fetchList = async (opts = {}) => {
    const { page = 0, size = pageInfo.size } = opts;
    setIsLoading(true);
    setError("");
    try {
      const hasAnyFilter =
        (q && q.trim()) || (writer && writer.trim()) || (commentId && String(commentId).trim()) || from || to;

      const url = hasAnyFilter
        ? ENDPOINTS.search({
            q,
            writer,
            commentId: commentId ? Number(commentId) : undefined,
            from,
            to,
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

  /** 삭제 */
  const handleDelete = async (idx) => {
    if (!window.confirm("정말 삭제하시겠습니까?")) return;
    try {
      const res = await fetch(ENDPOINTS.remove(idx), {
        method: "DELETE",
        credentials: "include",
        headers: buildHeaders(false),
      });
      if (!res.ok) {
        const text = await res.text().catch(() => "");
        throw new Error(`HTTP ${res.status}: ${text.slice(0, 160)}...`);
      }
      alert("삭제 성공!");
      fetchList({ page: pageInfo.number });
    } catch (e) {
      alert(e.message || "삭제 중 오류가 발생했습니다.");
    }
  };

  /** 선택(수정) */
  const handleSelect = (r) => {
    setSelected({ ...r });
    setIsCreating(false);
    setIsModalOpen(true);
  };

  /** 생성 모드 */
  const handleCreateClick = () => {
    setSelected({
      commentId: "",
      writer: "",
      commentContent: "",
      // commentDate는 생성 시 서버에서 자동 세팅
    });
    setIsCreating(true);
    setIsModalOpen(true);
  };

  /** 폼 변경 */
  const handleFormChange = (e) => {
    const { name, value } = e.target;
    setSelected((prev) => ({ ...prev, [name]: value }));
  };

  /** 저장(생성/수정) */
  const handleFormSubmit = async (e) => {
    e.preventDefault();
    if (!selected) return;

    try {
      if (isCreating) {
        // 생성: commentId, commentContent, writer 필요
        const payload = {
          commentId: Number(selected.commentId),
          commentContent: (selected.commentContent || "").trim(),
          writer: (selected.writer || "").trim(),
        };
        if (!payload.commentId || !payload.commentContent || !payload.writer) {
          alert("필수 입력을 확인하세요.");
          return;
        }
        const res = await fetch(ENDPOINTS.create(), {
          method: "POST",
          credentials: "include",
          headers: buildHeaders(true),
          body: JSON.stringify(payload),
        });
        if (!res.ok) {
          const text = await res.text().catch(() => "");
          throw new Error(`HTTP ${res.status}: ${text.slice(0, 160)}...`);
        }
        await parseJSONSafe(res);
        alert("댓글 생성 완료!");
      } else {
        // 수정: 내용/작성자만 변경(백엔드 서비스 로직에 맞춤)
        const payload = {
          commentContent: (selected.commentContent || "").trim(),
          writer: (selected.writer || "").trim(),
        };
        const res = await fetch(ENDPOINTS.update(selected.commentIdx), {
          method: "PUT",
          credentials: "include",
          headers: buildHeaders(true),
          body: JSON.stringify(payload),
        });
        if (!res.ok) {
          const text = await res.text().catch(() => "");
          throw new Error(`HTTP ${res.status}: ${text.slice(0, 160)}...`);
        }
        await parseJSONSafe(res);
        alert("댓글 수정 완료!");
      }

      setIsModalOpen(false);
      setSelected(null);
      setIsCreating(false);
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
      <h1 className="h3 mb-4 text-gray-800">댓글(Board Comments) 관리</h1>

      {/* 검색/생성 바 */}
      <div className="d-flex align-items-center mb-3" style={{ gap: 8, flexWrap: "wrap" }}>
        <button className="btn btn-primary" onClick={handleCreateClick}>새 댓글 생성</button>

        <form onSubmit={handleSearchSubmit} className="d-flex align-items-end" style={{ gap: 8, flexWrap: "wrap" }}>
          <div>
            <label className="form-label">키워드(q)</label>
            <input
              type="text"
              className="form-control"
              placeholder="내용 검색어"
              value={q}
              onChange={(e) => setQ(e.target.value)}
              style={{ width: 220 }}
            />
          </div>
          <div>
            <label className="form-label">작성자</label>
            <input
              type="text"
              className="form-control"
              placeholder="writer"
              value={writer}
              onChange={(e) => setWriter(e.target.value)}
              style={{ width: 160 }}
            />
          </div>
          <div>
            <label className="form-label">게시물ID</label>
            <input
              type="number"
              className="form-control"
              placeholder="commentId"
              value={commentId}
              onChange={(e) => setCommentId(e.target.value)}
              style={{ width: 140 }}
              min={0}
            />
          </div>
          <div>
            <label className="form-label">FROM</label>
            <input
              type="date"
              className="form-control"
              value={from}
              onChange={(e) => setFrom(e.target.value)}
            />
          </div>
          <div>
            <label className="form-label">TO</label>
            <input
              type="date"
              className="form-control"
              value={to}
              onChange={(e) => setTo(e.target.value)}
            />
          </div>
          <button type="submit" className="btn btn-secondary" style={{ height: 38 }}>검색</button>
        </form>
      </div>

      {isLoading && <div className="alert alert-info">불러오는 중...</div>}
      {error && <div className="alert alert-danger">{error}</div>}

      {/* 목록 */}
      <table className="table table-bordered">
        <thead>
          <tr>
            <th style={{ width: 100 }}>댓글ID</th>
            <th style={{ width: 110 }}>게시물ID</th>
            <th style={{ width: 160 }}>작성자</th>
            <th>내용</th>
            <th style={{ width: 220 }}>작성일시</th>
            <th style={{ width: 220 }}>관리</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((r) => (
            <tr key={r.commentIdx}>
              <td>{r.commentIdx}</td>
              <td>{r.commentId}</td>
              <td>{r.writer}</td>
              <td style={{ whiteSpace: "pre-wrap" }}>{r.commentContent}</td>
              <td>{formatDate(r.commentDate)}</td>
              <td>
                <button className="btn btn-info btn-sm mr-2" onClick={() => handleSelect(r)}>상세/수정</button>
                <button className="btn btn-danger btn-sm" onClick={() => handleDelete(r.commentIdx)}>삭제</button>
              </td>
            </tr>
          ))}
          {rows.length === 0 && !isLoading && (
            <tr><td colSpan={6} className="text-center text-muted">데이터가 없습니다.</td></tr>
          )}
        </tbody>
      </table>

      {/* 페이지네이션(옵션) */}
      <div className="d-flex align-items-center justify-content-between mb-3">
        <div>
          총 {pageInfo.totalElements}건 / {pageInfo.number + 1} / {pageInfo.totalPages} 페이지
        </div>
        <div style={{ display: "flex", gap: 8 }}>
          <button className="btn btn-outline-secondary btn-sm" disabled={pageInfo.number <= 0} onClick={prevPage}>이전</button>
          <button className="btn btn-outline-secondary btn-sm" disabled={pageInfo.number + 1 >= pageInfo.totalPages} onClick={nextPage}>다음</button>
        </div>
      </div>

      {/* 모달 */}
      {isModalOpen && (
        <div
          className="modal-backdrop"
          style={{
            position: "fixed", top: 0, left: 0, width: "100%", height: "100%",
            backgroundColor: "rgba(0,0,0,0.5)", display: "flex",
            justifyContent: "center", alignItems: "center", zIndex: 1000
          }}
        >
          <div className="modal-content p-4 bg-white" style={{ width: 560, borderRadius: 8 }}>
            <h4>{isCreating ? "댓글 생성" : `댓글 수정 / 상세 (ID: ${selected?.commentIdx})`}</h4>
            <form onSubmit={handleFormSubmit}>
              <div className="d-flex" style={{ gap: 8 }}>
                <div className="flex-fill">
                  <label className="form-label">게시물ID</label>
                  <input
                    type="number"
                    name="commentId"
                    value={selected?.commentId ?? ""}
                    onChange={handleFormChange}
                    className="form-control mb-2"
                    placeholder="어떤 게시물에 달린 댓글인지"
                    min={0}
                    disabled={!isCreating} // 수정 시 변경 금지(서비스 로직에 맞춤)
                    required
                  />
                </div>
                <div className="flex-fill">
                  <label className="form-label">작성자</label>
                  <input
                    type="text"
                    name="writer"
                    value={selected?.writer ?? ""}
                    onChange={handleFormChange}
                    className="form-control mb-2"
                    placeholder="writer"
                    maxLength={40}
                    required
                  />
                </div>
              </div>

              <label className="form-label">내용</label>
              <textarea
                name="commentContent"
                value={selected?.commentContent ?? ""}
                onChange={handleFormChange}
                className="form-control mb-3"
                rows={4}
                maxLength={300}
                placeholder="댓글 내용을 입력하세요 (최대 300자)"
                required
              />

              {!isCreating && (
                <div className="text-muted mb-2">
                  작성일시: {formatDate(selected?.commentDate)}
                </div>
              )}

              <button type="submit" className="btn btn-success">
                {isCreating ? "생성" : "수정"}
              </button>
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
