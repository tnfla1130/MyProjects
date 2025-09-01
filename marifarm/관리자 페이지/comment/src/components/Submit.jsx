import { useState } from "react"
  
function Submit ({save, setSave, onClose}){

  const [id, setid] = useState('');
  const [comment, setComment] = useState('');
  
  const handle = (e) => {
  console.log('렌더링');
    e.preventDefault();
    if(!id || !comment) {
      alert('글자를 입력하세요');
      return;
    }
    const newComment = {
      a:id,
      b:comment,
      createdAt: new Date().toLocaleString()
    };
    setSave([...save, newComment]);
    setComment('');
    setid('');
    onClose();
    console.log('작성',id,comment);
  };
  return (
        <div 
          className="modal fade" 
          id="commentModal" 
          tabIndex="-1" 
          aria-labelledby="commentModalLabel" 
          aria-hidden="true">
            <div className="modal-dialog">
                <div className="modal-content">
                    <div className="modal-header">
                        <h5 
                          className="modal-title" 
                          id="commentModalLabel">댓글 작성</h5>
                        <button type="button" 
                          className="btn-close" 
                          data-bs-dismiss="modal" 
                          aria-label="Close"></button>
                    </div>
                    <div className="modal-body">
                        <div className="mb-3">
                            <label 
                              htmlFor="commentAuthor" 
                              className="form-label">작성자명</label>
                              <input type="text" 
                                className="form-control" 
                                id="commentAuthor" 
                                placeholder="이름을 입력하세요"
                                value={id}
                                onChange={(e) => setid(e.target.value)}/>
                        </div>
                        <label 
                          htmlFor="commentContent" 
                          className="form-label">댓글 내용</label>
                          <textarea 
                            className="form-control" 
                            id="commentContent" 
                            rows="3" 
                            placeholder="댓글을 입력하세요"
                            value={comment}
                            onChange={(e) => setComment(e.target.value)}>
                          </textarea>
                    </div>
                    <div className="modal-footer">
                        <button type="button" className="btn btn-secondary" data-bs-dismiss="modal">닫기</button>
                        <button type="button" className="btn btn-primary" onClick={handle}>작성</button>
                    </div>
                </div>
            </div>
        </div>
  )
};
export default Submit;