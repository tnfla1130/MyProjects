

// ChatMessagesAdmin.jsx
import { useEffect, useState, useMemo } from "react";

/** ===== API ===== */
const API_HOST = "http://localhost:8080";
const ENDPOINTS = {
  // 쿼리스트링 방식만 사용 (roomId 없으면 호출 금지)
  list: ({ roomId, page = 0, size = 50, asc = false, sender, q, from, to }) => {
    const qs = new URLSearchParams({
      roomId: String(roomId),
      page: String(page),
      size: String(size),
      asc: String(asc),
    });
    if (sender != null && sender !== "") qs.set("sender", String(sender));
    if (q && q.trim()) qs.set("q", q.trim());
    if (from && from.trim()) qs.set("from", from.trim()); // YYYY-MM-DD
    if (to && to.trim()) qs.set("to", to.trim());         // YYYY-MM-DD
    return `${API_HOST}/api/admin/chat/messages?${qs.toString()}`;
  },
  send: (roomId) => `${API_HOST}/api/admin/chat/rooms/${roomId}/messages`,
  markReadRoom: (roomId) => `${API_HOST}/api/admin/chat/rooms/${roomId}/messages/mark-read`,
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
const fmt = (d) => (d ? new Date(d).toLocaleString() : "");

export default function ChatMessagesAdmin({ roomId, roomName }) {
  const [rows, setRows] = useState([]);
  const [pageInfo, setPageInfo] = useState({ number: 0, size: 50, totalPages: 1, totalElements: 0 });
  const [isLoading, setIsLoading] = useState(false);
  const [err, setErr] = useState("");

  // 검색 필터
  const [asc, setAsc] = useState(false);
  const [sender, setSender] = useState("");
  const [q, setQ] = useState("");
  const [from, setFrom] = useState(""); // YYYY-MM-DD
  const [to, setTo] = useState("");

  // 전송
  const [content, setContent] = useState("");

  const canQuery = useMemo(() => roomId != null && roomId !== "" && roomId !== "undefined", [roomId]);

  const fetchPage = async (p = 0) => {
    if (!canQuery) return; // roomId 없으면 호출 금지
    setIsLoading(true);
    setErr("");
    try {
      const url = ENDPOINTS.list({
        roomId,
        page: p,
        size: pageInfo.size,
        asc,
        sender,
        q,
        from,
        to,
      });
      const res = await fetch(url, { method: "GET", credentials: "include", headers: buildHeaders(false) });
      if (!res.ok) {
        const text = await res.text().catch(() => "");
        throw new Error(`HTTP ${res.status}: ${text.slice(0, 160)}...`);
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
    // roomId 바뀔 때마다 첫 페이지 로딩 (roomId 없으면 skip)
    if (canQuery) fetchPage(0);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [roomId]);

  const onSearch = (e) => {
    e?.preventDefault?.();
    fetchPage(0);
  };
  const prev = () => pageInfo.number > 0 && fetchPage(pageInfo.number - 1);
  const next = () => pageInfo.number + 1 < pageInfo.totalPages && fetchPage(pageInfo.number + 1);

  const sendMessage = async () => {
    if (!canQuery) return alert("roomId가 없습니다.");
    const body = { senderMemberIdx: Number(sender) || 0, content: content?.trim() || "" };
    if (!body.content) return;
    try {
      const res = await fetch(ENDPOINTS.send(roomId), {
        method: "POST",
        credentials: "include",
        headers: buildHeaders(true),
        body: JSON.stringify(body),
      });
      if (!res.ok) {
        const text = await res.text().catch(() => "");
        throw new Error(`HTTP ${res.status}: ${text.slice(0, 160)}...`);
      }
      await parseJSONSafe(res);
      setContent("");
      fetchPage(pageInfo.number); // 현재 페이지 갱신
    } catch (e) {
      alert(e.message || "전송 실패");
    }
  };

  const markReadAll = async () => {
    if (!canQuery) return;
    try {
      const res = await fetch(ENDPOINTS.markReadRoom(roomId), {
        method: "POST",
        credentials: "include",
        headers: buildHeaders(false),
      });
      if (!res.ok) {
        const text = await res.text().catch(() => "");
        throw new Error(`HTTP ${res.status}: ${text.slice(0, 160)}...`);
      }
      await parseJSONSafe(res);
      fetchPage(pageInfo.number);
    } catch (e) {
      alert(e.message || "읽음 처리 실패");
    }
  };

  return (
    <div>
      {!canQuery && (
        <div className="alert alert-warning">roomId가 없습니다. (props 확인) — 호출을 중단했습니다.</div>
      )}
      <div className="d-flex align-items-end mb-2" style={{ gap: 8, flexWrap: "wrap" }}>
        <div className="mr-3"><strong>Room:</strong> {roomName} (ID: {String(roomId)})</div>
        <form onSubmit={onSearch} className="d-flex align-items-end" style={{ gap: 8, flexWrap: "wrap" }}>
          <div>
            <label className="form-label">sender(memberIdx)</label>
            <input className="form-control" value={sender} onChange={(e) => setSender(e.target.value)} placeholder="숫자" />
          </div>
          <div>
            <label className="form-label">q</label>
            <input className="form-control" value={q} onChange={(e) => setQ(e.target.value)} placeholder="내용 검색" />
          </div>
          <div>
            <label className="form-label">from</label>
            <input className="form-control" type="date" value={from} onChange={(e) => setFrom(e.target.value)} />
          </div>
          <div>
            <label className="form-label">to</label>
            <input className="form-control" type="date" value={to} onChange={(e) => setTo(e.target.value)} />
          </div>
          <div>
            <label className="form-label">오름차순</label>
            <select className="form-control" value={asc ? "1" : "0"} onChange={(e) => setAsc(e.target.value === "1")}>
              <option value="0">false</option>
              <option value="1">true</option>
            </select>
          </div>
          <button type="submit" className="btn btn-secondary" style={{ height: 38 }} disabled={!canQuery}>검색</button>
          <button type="button" className="btn btn-outline-primary" style={{ height: 38 }} onClick={markReadAll} disabled={!canQuery}>방 전체 읽음</button>
        </form>
      </div>

      {isLoading && <div className="alert alert-info">불러오는 중...</div>}
      {err && <div className="alert alert-danger">{err}</div>}

      <table className="table table-bordered">
        <thead>
          <tr>
            <th style={{ width: 120 }}>ID</th>
            <th style={{ width: 180 }}>날짜</th>
            <th style={{ width: 120 }}>보낸이</th>
            <th>내용</th>
            <th style={{ width: 80 }}>읽음</th>
          </tr>
        </thead>
        <tbody>
          {rows.map(m => (
            <tr key={m.chatMessageIdx}>
              <td>{m.chatMessageIdx}</td>
              <td>{fmt(m.chatMessageDate)}</td>
              <td>{m.memberIdxMess}</td>
              <td>{m.chatMessageContent}</td>
              <td>{m.chatMessageIsRead ? "Y" : "N"}</td>
            </tr>
          ))}
          {rows.length === 0 && !isLoading && (
            <tr><td colSpan={5} className="text-center text-muted">내역 없음</td></tr>
          )}
        </tbody>
      </table>

      <div className="d-flex justify-content-between align-items-center">
        <div>총 {pageInfo.totalElements}건 / {pageInfo.number + 1} / {pageInfo.totalPages} 페이지</div>
        <div style={{ display: "flex", gap: 8 }}>
          <button className="btn btn-outline-secondary btn-sm" disabled={pageInfo.number <= 0} onClick={prev}>이전</button>
          <button className="btn btn-outline-secondary btn-sm" disabled={pageInfo.number + 1 >= pageInfo.totalPages} onClick={next}>다음</button>
        </div>
      </div>

      <div className="d-flex mt-3" style={{ gap: 8 }}>
        <input
          className="form-control"
          placeholder="메시지 내용"
          value={content}
          onChange={(e) => setContent(e.target.value)}
        />
        <button className="btn btn-primary" onClick={sendMessage} disabled={!canQuery || !content.trim()}>보내기</button>
      </div>
    </div>
  );
}
