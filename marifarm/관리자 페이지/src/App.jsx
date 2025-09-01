import { BrowserRouter, Route, Routes } from 'react-router-dom';
import MemberInformation from './member/MemberInformation';
import MainPage from './mainPage';
import Sidebar from './Sidebar';
import FreeBoard from './board/freeboard';
import Announcementboard from './board/Announcementboard';
import Transactionboard from './board/Transactionboard';
import CommentsAdmin from './board/CommentsAdmin';
import ChatRoomsAdmin from './chatting/ChatRoomsAdmin';
import PlantsAdmin from './plants/PlantsAdmin';
import UserGameAdmin from './game/UserGameAdmin';

function App() {

  return (<>
  <BrowserRouter>
    <Sidebar>
      <Routes>
        <Route path='/announcementboard' element={<Announcementboard/>}/>
        <Route path='/freeboard' element={<FreeBoard/>}/>
        <Route path="/" element={<MainPage/>}/>
        <Route path="/memberInformation" element={<MemberInformation/>}/>
        <Route path="/transactionboard" element={<Transactionboard/>}/>
        <Route path='/mainpage' element={<MainPage/>}/>
        <Route path='/comment' element={<CommentsAdmin/>}/>
        <Route path='/chatRoomsAdmin' element={<ChatRoomsAdmin/>}/>
        <Route path='/plantsAdmin' element={<PlantsAdmin/>}/>
        <Route path='/userGameAdmin' element={<UserGameAdmin/>}/> 
      </Routes>
    </Sidebar>
  </BrowserRouter>
  </>
  )
}

export default App
