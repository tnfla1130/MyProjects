import { useState, useEffect } from "react";

export default function Edit( {comment, index, onUpdate, onClose}) {
  const [id, setid] = useState('');
  const [text, setText] = useState('');
  useEffect(() => {
    if (comment) {
      setid(comment.a);
      setText(comment.b);
    }
  }, [comment]);
  const handleSubmit = (e) => {
    e.preventDefault();
    if (!id || !text) return;

    const updated = {
      a: id,
      b: text,
      createdAt: new Date().toLocaleString()
      
    };

    onUpdate(index, updated);
    onClose(); // 폼 닫기
  };

  return (
    <div className="modal fade show d-block" tabIndex="-1" role="dialog">
      <div className="modal-dialog">
        <div className="modal-content">
          <form onSubmit={handleSubmit}>
            <div className="modal-header">
              <h5 className="modal-title">댓글 수정</h5>
              <button type="button" className="btn-close" onClick={onClose}></button>
            </div>
            <div className="modal-body">
              <div className="mb-3">
                <label className="form-label">작성자명</label>
                <input
                  type="text"
                  className="form-control"
                  value={id}
                  onChange={(e) => setId(e.target.value)}
                  required
                />
              </div>
              <div className="mb-3">
                <label className="form-label">댓글 내용</label>
                <textarea
                  className="form-control"
                  rows="3"
                  value={text}
                  onChange={(e) => setText(e.target.value)}
                  required
                />
              </div>
            </div>
            <div className="modal-footer">
              <button type="button" className="btn btn-secondary" onClick={onClose}>취소</button>
              <button type="submit" className="btn btn-primary">저장</button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}