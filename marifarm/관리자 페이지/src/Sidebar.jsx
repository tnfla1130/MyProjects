import { Link } from "react-router-dom";

function Sidebar({ children }) {
  return (
    <div id="wrapper" style={{ display: "flex" }}>
      {/* 사이드바 */}
      <ul
        className="navbar-nav bg-gradient-primary sidebar sidebar-dark accordion"
        id="accordionSidebar"
        style={{ minWidth: "220px" }}
      >
        <a
          className="sidebar-brand d-flex align-items-center justify-content-center"
          href="index.html"
        >
          <div className="sidebar-brand-icon rotate-n-15">
            <i className="fas fa-laugh-wink"></i>
          </div>
          <div className="sidebar-brand-text mx-3">Admin</div>
        </a>

        <hr className="sidebar-divider my-0" />

        <li className="nav-item active">
          <Link className="nav-link" to="/mainpage">
            <i className="fas fa-fw fa-tachometer-alt"></i>
            <span>Dashboard</span>
          </Link>
        </li>

        <hr className="sidebar-divider" />
        <div className="sidebar-heading">회원관리</div>

        <li className="nav-item">
          
          <Link className="nav-link collapsed" to="/memberInformation">
            <i className="fas fa-fw fa-cog"></i>
            <span>회원정보</span>
          </Link>
        </li>

        <div className="sidebar-heading">게시판</div>
        <li className="nav-item">
          <Link className="nav-link collapsed" to="/announcementboard">
            <i className="fas fa-fw fa-cog"></i>
            <span>공지사항</span>
          </Link>
          <Link className="nav-link collapsed" to="/freeboard">
            <i className="fas fa-fw fa-cog"></i>
            <span>소통게시판</span>
          </Link>
          <Link className="nav-link collapsed" to="/transactionboard">
            <i className="fas fa-fw fa-cog"></i>
            <span>거래게시판</span>
          </Link>
          <Link className="nav-link collapsed" to="/comment">
            <i className="fas fa-fw fa-cog"></i>
            <span>댓글</span>
          </Link>
        </li>

        <div className="sidebar-heading">ai</div>
        <li className="nav-item">
          <Link className="nav-link collapsed" to="/plantsAdmin">
            <i className="fas fa-fw fa-cog"></i>
            <span>식물데이터</span>
          </Link>
        </li>
        <div className="sidebar-heading">게임</div>
        <li className="nav-item">
          <Link className="nav-link collapsed" to="/userGameAdmin">
            <i className="fas fa-fw fa-cog"></i>
            <span>게임관리</span>
          </Link>
        </li>
      
        <hr className="sidebar-divider d-none d-md-block" />
      </ul>

      {/* 👉 오른쪽 메인 컨텐츠 영역 */}
      <div style={{ flex: 1, padding: "20px" }}>
        {children}
      </div>
    </div>
  );
}

export default Sidebar;
