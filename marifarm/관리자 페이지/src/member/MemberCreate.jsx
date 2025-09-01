import { useState } from "react";

function MemberCreate({ isOpen, onClose, onCreate }) {
  const [form, setForm] = useState({
    userId: "",
    password: "",
    email: "",
    phone: "",
    nickname: "",
    memberAuth: "USER",
    domain: "",
    gamePoint: 0,
    gameExp: 0,
    gameLevel: 1,
    gameImages: "",
    address: "",
    detailAddress: "",
    postcode: "",
  });

  if (!isOpen) return null;

  const handleChange = (e) => {
    const { name, value } = e.target;
    setForm({ ...form, [name]: value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      await onCreate(form);
      onClose();
    } catch (error) {
      console.error("회원 생성 오류:", error);
    }
  };

  return (
    <div style={{
      position: "fixed", top: 0, left: 0, right: 0, bottom: 0,
      backgroundColor: "rgba(0,0,0,0.5)",
      display: "flex", justifyContent: "center", alignItems: "center",
      zIndex: 1000,
    }}>
      <div style={{
        background: "white", padding: "20px", borderRadius: "8px",
        width: "500px", maxHeight: "90vh", overflowY: "auto"
      }}>
        <h2>회원 생성</h2>
        <form onSubmit={handleSubmit}>
          <input name="userId" value={form.userId} onChange={handleChange} placeholder="아이디" required /><br />
          <input type="password" name="password" value={form.password} onChange={handleChange} placeholder="비밀번호" required /><br />
          <input name="email" value={form.email} onChange={handleChange} placeholder="이메일" required /><br />
          <input name="phone" value={form.phone} onChange={handleChange} placeholder="전화번호" /><br />
          <input name="nickname" value={form.nickname} onChange={handleChange} placeholder="닉네임" required /><br />
          <input name="memberAuth" value={form.memberAuth} onChange={handleChange} placeholder="권한" required /><br />
          <input name="domain" value={form.domain} onChange={handleChange} placeholder="도메인" required /><br />
          <input type="number" name="gamePoint" value={form.gamePoint} onChange={handleChange} placeholder="게임재화" /><br />
          <input type="number" name="gameExp" value={form.gameExp} onChange={handleChange} placeholder="게임 경험치" /><br />
          <input type="number" name="gameLevel" value={form.gameLevel} onChange={handleChange} placeholder="게임 레벨" /><br />
          <input name="gameImages" value={form.gameImages} onChange={handleChange} placeholder="게임 이미지 URL" /><br />
          <input name="address" value={form.address} onChange={handleChange} placeholder="주소" required /><br />
          <input name="detailAddress" value={form.detailAddress} onChange={handleChange} placeholder="상세 주소" required /><br />
          <input name="postcode" value={form.postcode} onChange={handleChange} placeholder="우편번호" required /><br />
          <button type="submit" style={{ marginTop: "10px" }}>생성</button>
          <button type="button" onClick={onClose} style={{ marginLeft: "10px" }}>취소</button>
        </form>
      </div>
    </div>
  );
}

export default MemberCreate;
