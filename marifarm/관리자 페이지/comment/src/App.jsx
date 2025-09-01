import CommentList from "./components/commentList";
import Submit from "./components/Submit";
import { useState } from "react";
import Edit from "./components/edit";

function App() {
  const [modalOpen, setModalOpen] = useState(false);
  const [edit, setEdit] = useState(null);
  const [save, setSave] = useState([]);

  const handleLike = (index) => {
  const newSave = [...save];
  const current = newSave[index];
  newSave[index] = {
    ...current,
    likes: (current.likes || 0) + 1
  };
  setSave(newSave);
};
  const deleteComment = (index) => {
    setSave(save.filter((_, i) => i !== index));
  };
  const upDate = (index, updateComments)=>{
    const newSave = [...save];
    newSave[index] = updateComments; 
    setSave(newSave);
    setEdit(null);
  };
  const startEdit = (index) => {
    setEdit(index);
  }
  return (
    <>
    <h2>댓글 작성 구현하기</h2>
      <button onClick={() => setModalOpen(true)}>댓글 작성</button>
    <p>
      댓글은 여기에 출력됩니다. 줄바꿈 처리도 해주세요. <br/>
      댓글 작성과 수정은 모달창을 이용하면 됩니다. 
    </p>
      {modalOpen && 
        <Submit 
        onClose={() => setModalOpen(false)} 
        save={save} 
        setSave={setSave} />}
        {Edit !== null && save[edit]&&(<Edit 
          comment={save[edit]}
          index={edit}
          onUpdate={upDate}
          onClose={() => setEdit(null)}/>)}
        <CommentList 
        comments={save}
        onDelete={deleteComment}
        onEdit={startEdit}
        onLike={handleLike}
      />
        </>
  )
}

export default App
