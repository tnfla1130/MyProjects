import { useEffect, useState } from "react";

const API_HOST = "http://localhost:8080";
const ENDPOINTS = {
  list: () => `${API_HOST}/api/transaction`,
  search: (kw) => `${API_HOST}/api/transaction/search?keyword=${encodeURIComponent(kw)}`,
  create: () => `${API_HOST}/api/transaction`,
  update: (id) => `${API_HOST}/api/transaction/${id}`,
  remove: (id) => `${API_HOST}/api/transaction/${id}`,
  photoUpload: (id, slot) => `${API_HOST}/api/transaction/${id}/photo/${slot}`,
  photoClear: (id, slot) => `${API_HOST}/api/transaction/${id}/photo/${slot}`,
};

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

function toLocalInputValue(d) {
  if (!d) return "";
  const date = new Date(d);
  if (Number.isNaN(date.getTime())) return "";
  const pad = (n) => String(n).padStart(2, "0");
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

// ===== 공통: 인증 헤더 + 안전한 JSON 파서 =====
const getToken = () => localStorage.getItem("token"); // 필요 시 토큰 저장소에 맞게 변경
const buildHeaders = (json = false) => {
  const h = {
    Accept: "application/json",
    "X-Requested-With": "XMLHttpRequest",
  };
  const t = getToken();
  if (t) h.Authorization = `Bearer ${t}`;
  if (json) h["Content-Type"] = "application/json"; // multipart 전송 시는 설정 금지
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

export default function Transactionboard() {
  const [rows, setRows] = useState([]);
  const [searchKeyword, setSearchKeyword] = useState("");
  const [selected, setSelected] = useState(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isCreating, setIsCreating] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");

  // 파일 업로드 상태
  const [files, setFiles] = useState({ 1: null, 2: null, 3: null });
  const [previews, setPreviews] = useState({ 1: "", 2: "", 3: "" });
  const [uploading, setUploading] = useState({ 1: false, 2: false, 3: false });

  const fetchList = async (keyword = "") => {
    setIsLoading(true);
    setError("");
    try {
      const url = keyword && keyword.trim() ? ENDPOINTS.search(keyword.trim()) : ENDPOINTS.list();
      const res = await fetch(url, { method: "GET", credentials: "include", headers: buildHeaders(false) });
      if (!res.ok) {
        const text = await res.text().catch(() => "");
        throw new Error(`HTTP ${res.status}: ${text.slice(0, 160)}...`);
      }
      const data = await parseJSONSafe(res);
      const list = Array.isArray(data) ? data : data?.content ?? [];
      setRows(list);
    } catch (e) {
      setError(e.message || String(e));
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => { fetchList(""); }, []);
  useEffect(() => {
    const id = setTimeout(() => { fetchList(searchKeyword); }, 300);
    return () => clearTimeout(id);
  }, [searchKeyword]);

  const handleDelete = async (id) => {
    if (!window.confirm("정말 삭제하시겠습니까?")) return;
    try {
      const res = await fetch(ENDPOINTS.remove(id), { method: "DELETE", credentials: "include", headers: buildHeaders(false) });
      if (!res.ok) {
        const text = await res.text().catch(() => "");
        throw new Error(`HTTP ${res.status}: ${text.slice(0, 160)}...`);
      }
      // 204 예상
      alert("삭제 성공!");
      fetchList(searchKeyword);
    } catch (e) {
      alert(e.message || "삭제 중 오류가 발생했습니다.");
    }
  };

  const handleSelect = (r) => {
    setSelected({ ...r });
    setIsCreating(false);
    setIsModalOpen(true);
    setFiles({ 1: null, 2: null, 3: null });
    setPreviews({ 1: "", 2: "", 3: "" });
  };

  const handleCreateClick = () => {
    setSelected({
      transactionTitle: "",
      transactionContent: "",
      transactionPrice: 0,
      transactionIsTrans: "N",
      transactionDate: "",
    });
    setIsCreating(true);
    setIsModalOpen(true);
    setFiles({ 1: null, 2: null, 3: null });
    setPreviews({ 1: "", 2: "", 3: "" });
  };

  const handleFormChange = (e) => {
    const { name, value } = e.target;
    setSelected((prev) => ({ ...prev, [name]: value }));
  };

  const handlePriceChange = (e) => {
    const v = e.target.value;
    const num = Number(v.replace(/[^0-9]/g, ""));
    setSelected((prev) => ({ ...prev, transactionPrice: Number.isNaN(num) ? 0 : num }));
  };

  const handleDateChange = (e) => {
    setSelected((prev) => ({ ...prev, transactionDate: e.target.value }));
  };

  // 파일 선택 -> 미리보기 & (수정모드면) 즉시 업로드
  const handlePickFile = (slot) => async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const url = URL.createObjectURL(file);
    setPreviews((p) => ({ ...p, [slot]: url }));
    setFiles((f) => ({ ...f, [slot]: file }));

    if (!isCreating) {
      await uploadPhoto(slot, file);
      URL.revokeObjectURL(url);
    }
  };

  const uploadPhoto = async (slot, file) => {
    if (!selected?.transactionIdx) return; // 생성 모드에선 저장 후 업로드
    try {
      setUploading((u) => ({ ...u, [slot]: true }));
      const fd = new FormData();
      fd.append("file", file);
      const res = await fetch(ENDPOINTS.photoUpload(selected.transactionIdx, slot), {
        method: "POST",
        credentials: "include",
        headers: buildHeaders(false), // multipart: Content-Type 자동 설정
        body: fd,
      });
      if (!res.ok) {
        const text = await res.text().catch(() => "");
        throw new Error(`HTTP ${res.status}: ${text.slice(0, 160)}...`);
      }
      const updated = await parseJSONSafe(res);
      setSelected(updated);
      fetchList(searchKeyword);
      alert(`사진 ${slot} 업로드 완료`);
    } catch (e) {
      alert(e.message || `사진 ${slot} 업로드 중 오류`);
    } finally {
      setUploading((u) => ({ ...u, [slot]: false }));
    }
  };

  const clearPhoto = async (slot) => {
    if (!selected?.transactionIdx) {
      setFiles((f) => ({ ...f, [slot]: null }));
      setPreviews((p) => ({ ...p, [slot]: "" }));
      setSelected((s) => ({ ...s, [`ofile${slot}`]: "" }));
      return;
    }
    try {
      const res = await fetch(ENDPOINTS.photoClear(selected.transactionIdx, slot), {
        method: "DELETE",
        credentials: "include",
        headers: buildHeaders(false),
      });
      if (!res.ok) {
        const text = await res.text().catch(() => "");
        throw new Error(`HTTP ${res.status}: ${text.slice(0, 160)}...`);
      }
      const updated = await parseJSONSafe(res);
      setSelected(updated);
      fetchList(searchKeyword);
    } catch (e) {
      alert(e.message || `사진 ${slot} 삭제 중 오류`);
    }
  };

  const handleFormSubmit = async (e) => {
    e.preventDefault();
    if (!selected) return;

    const payload = {
      transactionTitle: selected.transactionTitle?.trim(),
      transactionContent: selected.transactionContent?.trim(),
      transactionPrice: Number(selected.transactionPrice) || 0,
      transactionIsTrans: (selected.transactionIsTrans || "N").toString().slice(0, 1),
    };
    if (selected.transactionDate) {
      const local = new Date(selected.transactionDate);
      if (!Number.isNaN(local.getTime())) payload.transactionDate = local.toISOString();
    }

    try {
      const url = isCreating ? ENDPOINTS.create() : ENDPOINTS.update(selected.transactionIdx);
      const res = await fetch(url, {
        method: isCreating ? "POST" : "PATCH",
        credentials: "include",
        headers: buildHeaders(true),
        body: JSON.stringify(payload),
      });
      if (!res.ok) {
        const text = await res.text().catch(() => "");
        throw new Error(`HTTP ${res.status}: ${text.slice(0, 160)}...`);
      }
      const saved = await parseJSONSafe(res);

      if (isCreating && (files[1] || files[2] || files[3])) {
        const newId = saved.transactionIdx;
        for (const slot of [1, 2, 3]) {
          const f = files[slot];
          if (!f) continue;
          const fd = new FormData();
          fd.append("file", f);
          const up = await fetch(ENDPOINTS.photoUpload(newId, slot), {
            method: "POST",
            credentials: "include",
            headers: buildHeaders(false),
            body: fd,
          });
          if (!up.ok) {
            const text = await up.text().catch(() => "");
            throw new Error(`HTTP ${up.status}: ${text.slice(0, 160)}...`);
          }
        }
      }

      alert(isCreating ? "거래 생성/사진 업로드 완료!" : "거래 수정 완료!");
      setIsModalOpen(false);
      setSelected(null);
      setIsCreating(false);
      setFiles({ 1: null, 2: null, 3: null });
      setPreviews({ 1: "", 2: "", 3: "" });
      fetchList(searchKeyword);
    } catch (e) {
      alert(e.message || "저장 중 오류가 발생했습니다.");
    }
  };

  return (
    <div className="container-fluid">
      <h1 className="h3 mb-4 text-gray-800">거래(Transactions) 관리</h1>

      <div className="d-flex align-items-center mb-3" style={{ gap: 8 }}>
        <button className="btn btn-primary" onClick={handleCreateClick}>새 거래 생성</button>
        <form onSubmit={(e) => { e.preventDefault(); fetchList(searchKeyword); }} className="d-flex" style={{ gap: 8 }}>
          <input
            type="text"
            className="form-control"
            placeholder="제목/내용 검색"
            value={searchKeyword}
            style={{ width: 420, padding: 6 }}
            onChange={(e) => setSearchKeyword(e.target.value)}
          />
          <button type="submit" className="btn btn-secondary">검색</button>
        </form>
      </div>

      {isLoading && <div className="alert alert-info">불러오는 중...</div>}
      {error && <div className="alert alert-danger">{error}</div>}

      <table className="table table-bordered">
        <thead>
          <tr>
            <th style={{ width: 90 }}>번호</th>
            <th>제목</th>
            <th style={{ width: 120 }}>가격</th>
            <th style={{ width: 200 }}>거래일자</th>
            <th style={{ width: 90 }}>확인</th>
            <th style={{ width: 260 }}>관리</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((r) => (
            <tr key={r.transactionIdx}>
              <td>{r.transactionIdx}</td>
              <td>{r.transactionTitle}</td>
              <td>{r.transactionPrice?.toLocaleString?.() ?? r.transactionPrice}</td>
              <td>{formatDate(r.transactionDate)}</td>
              <td>{r.transactionIsTrans}</td>
              <td>
                <button className="btn btn-info btn-sm mr-2" onClick={() => handleSelect(r)}>상세/수정</button>
                <button className="btn btn-danger btn-sm" onClick={() => handleDelete(r.transactionIdx)}>삭제</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      {isModalOpen && (
        <div
          className="modal-backdrop"
          style={{ position: "fixed", top: 0, left: 0, width: "100%", height: "100%", backgroundColor: "rgba(0,0,0,0.5)", display: "flex", justifyContent: "center", alignItems: "center", zIndex: 1000 }}
        >
          <div className="modal-content p-4 bg-white" style={{ width: 560, borderRadius: 8 }}>
            <h4>{isCreating ? "거래 생성" : `거래 수정 / 상세 (ID: ${selected?.transactionIdx})`}</h4>
            <form onSubmit={handleFormSubmit}>
              <input
                name="transactionTitle"
                value={selected?.transactionTitle ?? ""}
                onChange={handleFormChange}
                placeholder="제목"
                required
                className="form-control mb-2"
              />

              <textarea
                name="transactionContent"
                value={selected?.transactionContent ?? ""}
                onChange={handleFormChange}
                placeholder="내용"
                className="form-control mb-2"
                rows={4}
              />

              <div className="d-flex" style={{ gap: 8 }}>
                <div className="flex-fill">
                  <label className="form-label">가격</label>
                  <input
                    type="text"
                    inputMode="numeric"
                    name="transactionPrice"
                    value={selected?.transactionPrice ?? 0}
                    onChange={handlePriceChange}
                    className="form-control mb-2"
                  />
                </div>
                <div>
                  <label className="form-label">확인</label>
                  <select
                    name="transactionIsTrans"
                    value={selected?.transactionIsTrans ?? "N"}
                    onChange={handleFormChange}
                    className="form-control mb-2"
                  >
                    <option value="N">N</option>
                    <option value="Y">Y</option>
                  </select>
                </div>
              </div>

              <label className="form-label">거래일자</label>
              <input
                type="datetime-local"
                value={toLocalInputValue(selected?.transactionDate)}
                onChange={handleDateChange}
                className="form-control mb-3"
              />

              {/* 사진 업로드 UI */}
              <div className="mb-3">
                <label className="form-label d-block">사진 (최대 3장)</label>
                {[1, 2, 3].map((slot) => (
                  <div key={slot} className="d-flex align-items-center mb-2" style={{ gap: 8 }}>
                    <input type="file" accept="image/*" onChange={handlePickFile(slot)} />
                    {previews[slot] ? (
                      <img
                        alt={`preview-${slot}`}
                        src={previews[slot]}
                        style={{ width: 60, height: 60, objectFit: "cover", borderRadius: 6 }}
                      />
                    ) : selected?.[`ofile${slot}`] ? (
                      <span className="text-muted" title={selected[`ofile${slot}`]}>
                        {selected[`ofile${slot}`]}
                      </span>
                    ) : (
                      <span className="text-muted">선택된 파일 없음</span>
                    )}
                    {!isCreating && files[slot] && (
                      <button
                        type="button"
                        className="btn btn-outline-primary btn-sm"
                        disabled={uploading[slot]}
                        onClick={() => uploadPhoto(slot, files[slot])}
                      >
                        {uploading[slot] ? "업로드 중..." : "업로드"}
                      </button>
                    )}
                    <button
                      type="button"
                      className="btn btn-outline-danger btn-sm"
                      onClick={() => clearPhoto(slot)}
                    >
                      제거
                    </button>
                  </div>
                ))}
              </div>

              <button type="submit" className="btn btn-success">
                {isCreating ? "생성 (완료 후 사진 업로드)" : "수정"}
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
