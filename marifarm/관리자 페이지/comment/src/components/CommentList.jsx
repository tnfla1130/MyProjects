function CommentList ({comments, onDelete ,onEdit, onLike}) {
  
  return (
   
        <ul className="list-group mt-3">
          {comments.map((newComment,num) => (
            <li key={num} className="list-group-item">
              <div className="d-flex justify-content-between">
                <div className="d-flex align-items-center">
                  <strong>작성자명:{newComment.a}</strong> <small className="ms-2">{newComment.createdAt}</small>
                    </div>
                    <div>
                        <button 
                        className="btn btn-outline-success btn-sm"
                        onClick={() => onLike(num)}
                        >좋아요 ({newComment.likes || 0})</button>
                        <button 
                        className="btn btn-outline-warning btn-sm"
                        onClick={() => {
                          onEdit(num)
                        }}>수정</button>
                        <button className="btn btn-outline-danger btn-sm"
                        onClick={() => {

                          if(window.confirm('삭제할래?')){
                            onDelete(num);
                          }
                          else {
                            return;
                          }
                        }}
                        >삭제</button>
                    </div>
                  </div>
                <p className="mt-2 mb-0">
                  {newComment.b}
                </p>
            </li>
          ))}
        </ul>
  )
};
export default CommentList
