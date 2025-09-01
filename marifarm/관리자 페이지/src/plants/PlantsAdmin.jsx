// PlantsAdmin.jsx
import { useEffect, useState, useMemo } from "react";

/** ===== API ===== */
const API_HOST = "http://localhost:8080";
const ENDPOINTS = {
  list: ({ q = "", difficulty = "", page = 0, size = 20, sort = "" }) => {
    const qs = new URLSearchParams({
      page: String(page),
      size: String(size),
    });
    if (q && q.trim()) qs.set("q", q.trim());
    if (difficulty && difficulty.trim()) qs.set("difficulty", difficulty.trim());
    if (sort && sort.trim()) qs.set("sort", sort.trim()); // 예: "name,asc"
    return `${API_HOST}/api/plants?${qs.toString()}`;
  },
  get: (id) => `${API_HOST}/api/plants/${id}`,
  create: () => `${API_HOST}/api/plants`,
  update: (id) => `${API_HOST}/api/plants/${id}`,
  remove: (id) => `${API_HOST}/api/plants/${id}`,
};

const getToken = () => localStorage.getItem("token");
const buildHeaders = (json = false) => {
  const h = { Accept: "application/json", "X-Requested-With": "XMLHttpRequest" };
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

export default function PlantsAdmin() {
  const [rows, setRows] = useState([]);
  const [pageInfo, setPageInfo] = useState({ number: 0, size: 20, totalPages: 1, totalElements: 0 });
  const [isLoading, setIsLoading] = useState(false);
  const [err, setErr] = useState("");

  // 검색/필터/정렬
  const [q, setQ] = useState("");
  const [difficulty, setDifficulty] = useState(""); // '', '1', '2', '3' …
  const [sort, setSort] = useState("plantsIdx,asc"); // 서버와 합의된 sort 문자열

  // 생성/수정
  const [selected, setSelected] = useState(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isCreating, setIsCreating] = useState(false);

  const fetchPage = async (p = 0) => {
    setIsLoading(true);
    setErr("");
    try {
      const url = ENDPOINTS.list({ q, difficulty, page: p, size: pageInfo.size, sort });
      const res = await fetch(url, { method: "GET", credentials: "include", headers: buildHeaders(false) });
      if (!res.ok) {
        const t = await res.text().catch(() => "");
        throw new Error(`HTTP ${res.status}: ${t.slice(0, 160)}...`);
      }
      const data = await parseJSONSafe(res);
      const list = Array.isArray(data) ? data : data?.content ?? [];
      setRows(list);
      if (!Array.isArray(data) && data) {
        setPageInfo({
          number: data.number ?? p,
          size: data.size ?? pageInfo.size,
          totalPages: data.totalPages ?? 1,
          totalElements: data.totalElements ?? list.length,
        });
      } else {
        setPageInfo({ number: 0, size: pageInfo.size, totalPages: 1, totalElements: list.length });
      }
    } catch (e) {
      setErr(e.message || String(e));
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchPage(0);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const onSearch = (e) => {
    e?.preventDefault?.();
    fetchPage(0);
  };
  const prev = () => pageInfo.number > 0 && fetchPage(pageInfo.number - 1);
  const next = () => pageInfo.number + 1 < pageInfo.totalPages && fetchPage(pageInfo.number + 1);

  // 숫자 필드 변환 도우미
  const toNum = (v, isFloat = false) => {
    if (v === "" || v == null) return null;
    return isFloat ? parseFloat(v) : parseInt(v, 10);
  };

  // 생성 클릭
  const handleCreateClick = () => {
    setSelected({
      name: "",
      englishName: "",
      difficulty: "",
      minTemp: "",
      maxTemp: "",
      minGrowDays: "",
      maxGrowDays: "",
    });
    setIsCreating(true);
    setIsModalOpen(true);
  };

  // 행 선택(수정)
  const handleSelect = (r) => {
    setSelected({
      plantsIdx: r.plantsIdx,
      name: r.name ?? "",
      englishName: r.englishName ?? "",
      difficulty: r.difficulty ?? "",
      minTemp: r.minTemp ?? "",
      maxTemp: r.maxTemp ?? "",
      minGrowDays: r.minGrowDays ?? "",
      maxGrowDays: r.maxGrowDays ?? "",
    });
    setIsCreating(false);
    setIsModalOpen(true);
  };

  // 폼 변경
  const handleFormChange = (e) => {
    const { name, value } = e.target;
    setSelected((prev) => ({ ...prev, [name]: value }));
  };

  // 저장(생성/수정)
  const handleFormSubmit = async (e) => {
    e.preventDefault();
    if (!selected) return;

    const payload = {
      name: String(selected.name || "").trim(),
      englishName: String(selected.englishName || "").trim(),
      difficulty: String(selected.difficulty || "").trim(), // 1글자
      minTemp: toNum(selected.minTemp, true),
      maxTemp: toNum(selected.maxTemp, true),
      minGrowDays: toNum(selected.minGrowDays, false),
      maxGrowDays: toNum(selected.maxGrowDays, false),
    };

    try {
      if (isCreating) {
        const res = await fetch(ENDPOINTS.create(), {
          method: "POST",
          credentials: "include",
          headers: buildHeaders(true),
          body: JSON.stringify(payload),
        });
        if (!res.ok) {
          const t = await res.text().catch(() => "");
          throw new Error(`HTTP ${res.status}: ${t.slice(0, 160)}...`);
        }
        await parseJSONSafe(res);
        alert("식물 정보 생성 완료!");
      } else {
        if (!selected.plantsIdx) return alert("수정할 ID가 없습니다.");
        const res = await fetch(ENDPOINTS.update(selected.plantsIdx), {
          method: "PUT",
          credentials: "include",
          headers: buildHeaders(true),
          body: JSON.stringify(payload),
        });
        if (!res.ok) {
          const t = await res.text().catch(() => "");
          throw new Error(`HTTP ${res.status}: ${t.slice(0, 160)}...`);
        }
        await parseJSONSafe(res);
        alert("식물 정보 수정 완료!");
      }
      setIsModalOpen(false);
      setIsCreating(false);
      setSelected(null);
      fetchPage(pageInfo.number);
    } catch (error) {
      alert(error.message || "저장 중 오류");
    }
  };

  // 삭제
  const handleDelete = async (id) => {
    if (!window.confirm("정말 삭제하시겠습니까?")) return;
    try {
      const res = await fetch(ENDPOINTS.remove(id), {
        method: "DELETE",
        credentials: "include",
        headers: buildHeaders(false),
      });
      if (!res.ok && res.status !== 204) {
        const t = await res.text().catch(() => "");
        throw new Error(`HTTP ${res.status}: ${t.slice(0, 160)}...`);
      }
      alert("삭제 완료!");
      // 현재 페이지 재조회 (요소가 사라져 빈 페이지가 되면 한 페이지 앞으로 이동)
      const isLastItemOnPage = rows.length === 1 && pageInfo.number > 0;
      fetchPage(isLastItemOnPage ? pageInfo.number - 1 : pageInfo.number);
    } catch (e) {
      alert(e.message || "삭제 실패");
    }
  };

  return (
    <div className="container-fluid">
      <h1 className="h3 mb-4 text-gray-800">식물 정보 관리</h1>
      <button className="btn btn-primary mb-3" onClick={handleCreateClick}>
        새 식물 등록
      </button>

      {/* 검색/필터/정렬 */}
      <form onSubmit={onSearch} className="d-flex mb-3" style={{ gap: 8, flexWrap: "wrap" }}>
        <input
          type="text"
          className="form-control"
          placeholder="이름 / 영어명 검색"
          value={q}
          style={{ width: 300 }}
          onChange={(e) => setQ(e.target.value)}
        />
        <select className="form-control" style={{ width: 150 }} value={difficulty} onChange={(e) => setDifficulty(e.target.value)}>
          <option value="">난이도(전체)</option>
          <option value="1">1</option>
          <option value="2">2</option>
          <option value="3">3</option>
        </select>

        <select className="form-control" style={{ width: 180 }} value={sort} onChange={(e) => setSort(e.target.value)}>
          <option value="plantsIdx,asc">ID 오름차순</option>
          <option value="plantsIdx,desc">ID 내림차순</option>
          <option value="name,asc">이름 오름차순</option>
          <option value="name,desc">이름 내림차순</option>
          <option value="englishName,asc">영문명 오름차순</option>
          <option value="englishName,desc">영문명 내림차순</option>
        </select>

        <button type="submit" className="btn btn-secondary">검색</button>
      </form>

      {isLoading && <div className="alert alert-info">불러오는 중...</div>}
      {err && <div className="alert alert-danger">{err}</div>}

      {/* 목록 */}
      <table className="table table-bordered">
        <thead>
          <tr>
            <th style={{ width: 90 }}>ID</th>
            <th style={{ width: 170 }}>이름</th>
            <th style={{ width: 200 }}>영문명</th>
            <th style={{ width: 90 }}>난이도</th>
            <th style={{ width: 180 }}>온도(최소~최대)</th>
            <th style={{ width: 200 }}>성장일수(최소~최대)</th>
            <th style={{ width: 160 }}>관리</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((r, i) => (
            <tr key={r.plantsIdx ?? i}>
              <td>{r.plantsIdx}</td>
              <td>{r.name}</td>
              <td>{r.englishName}</td>
              <td>{r.difficulty}</td>
              <td>{r.minTemp} ~ {r.maxTemp}</td>
              <td>{r.minGrowDays} ~ {r.maxGrowDays}</td>
              <td>
                <button className="btn btn-info btn-sm mr-2" onClick={() => handleSelect(r)}>수정</button>
                <button className="btn btn-danger btn-sm" onClick={() => handleDelete(r.plantsIdx)}>삭제</button>
              </td>
            </tr>
          ))}
          {rows.length === 0 && !isLoading && (
            <tr><td colSpan={7} className="text-center text-muted">내역 없음</td></tr>
          )}
        </tbody>
      </table>

      {/* 페이지네이션 */}
      <div className="d-flex justify-content-between align-items-center mb-3">
        <div>총 {pageInfo.totalElements}건 / {pageInfo.number + 1} / {pageInfo.totalPages} 페이지</div>
        <div style={{ display: "flex", gap: 8 }}>
          <button className="btn btn-outline-secondary btn-sm" disabled={pageInfo.number <= 0} onClick={prev}>이전</button>
          <button className="btn btn-outline-secondary btn-sm" disabled={pageInfo.number + 1 >= pageInfo.totalPages} onClick={next}>다음</button>
        </div>
      </div>

      {/* 모달 */}
      {isModalOpen && (
        <div
          className="modal-backdrop"
          style={{
            position: "fixed", top: 0, left: 0, width: "100%", height: "100%",
            backgroundColor: "rgba(0,0,0,0.5)", display: "flex", justifyContent: "center", alignItems: "center", zIndex: 1000,
          }}
        >
          <div className="modal-content p-4 bg-white" style={{ width: 520, borderRadius: 8 }}>
            <h4>{isCreating ? "식물 생성" : "식물 수정"}</h4>
            <form onSubmit={handleFormSubmit}>
              <input
                name="name"
                value={selected?.name || ""}
                onChange={handleFormChange}
                placeholder="이름"
                required
                className="form-control mb-2"
              />
              <input
                name="englishName"
                value={selected?.englishName || ""}
                onChange={handleFormChange}
                placeholder="영문명"
                required
                className="form-control mb-2"
              />
              <select
                name="difficulty"
                value={selected?.difficulty || ""}
                onChange={handleFormChange}
                required
                className="form-control mb-2"
              >
                <option value="">난이도 선택</option>
                <option value="1">1 (쉬움)</option>
                <option value="2">2 (보통)</option>
                <option value="3">3 (어려움)</option>
              </select>

              <div className="d-flex" style={{ gap: 8 }}>
                <input
                  type="number"
                  step="0.1"
                  name="minTemp"
                  value={selected?.minTemp ?? ""}
                  onChange={handleFormChange}
                  placeholder="최소온도"
                  required
                  className="form-control mb-2"
                />
                <input
                  type="number"
                  step="0.1"
                  name="maxTemp"
                  value={selected?.maxTemp ?? ""}
                  onChange={handleFormChange}
                  placeholder="최대온도"
                  required
                  className="form-control mb-2"
                />
              </div>

              <div className="d-flex" style={{ gap: 8 }}>
                <input
                  type="number"
                  name="minGrowDays"
                  value={selected?.minGrowDays ?? ""}
                  onChange={handleFormChange}
                  placeholder="최소 성장일수"
                  required
                  className="form-control mb-2"
                />
                <input
                  type="number"
                  name="maxGrowDays"
                  value={selected?.maxGrowDays ?? ""}
                  onChange={handleFormChange}
                  placeholder="최대 성장일수"
                  required
                  className="form-control mb-2"
                />
              </div>

              <button type="submit" className="btn btn-success">{isCreating ? "생성" : "수정"}</button>
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
