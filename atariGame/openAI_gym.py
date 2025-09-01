
import cv2
import pygame 
import gym
from gym.utils.play import play



pygame.display.init()
pygame.joystick.init()

joystick = pygame.joystick.Joystick(0)
joystick.init()

try:
    jid = joystick.get_instance_id()
except AttributeError:
    jid = joystick.get_id()
    
try:
    guid = joystick.get_guid()
except AttributeError:
    pass

image_start = cv2.imread('C:/Users/soolim/Desktop/coding/LAB/atari/image/game_start.jpg')
image_system = cv2.imread('C:/Users/soolim/Desktop/coding/LAB/atari/image/game_system.jpg')
image_system_ = cv2.imread('C:/Users/soolim/Desktop/coding/LAB/atari/image/game_system2.jpg')
image_quit = cv2.imread('C:/Users/soolim/Desktop/coding/LAB/atari/image/game_quit.jpg')
image_list1 = cv2.imread('C:/Users/soolim/Desktop/coding/LAB/atari/image/list_riverriad.jpg')
image_list2 = cv2.imread('C:/Users/soolim/Desktop/coding/LAB/atari/image/list_alien.jpg')
image_list3 = cv2.imread('C:/Users/soolim/Desktop/coding/LAB/atari/image/list_Berzerk.jpg')
image_list4 = cv2.imread('C:/Users/soolim/Desktop/coding/LAB/atari/image/list_Frostbite.jpg')
tanker = cv2.imread('C:/Users/soolim/Desktop/coding/LAB/atari/image/score.png',cv2.IMREAD_UNCHANGED)
helicopter = cv2.imread('C:/Users/soolim/Desktop/coding/LAB/atari/image/Helicopter.png',cv2.IMREAD_UNCHANGED)
fuel = cv2.imread('C:/Users/soolim/Desktop/coding/LAB/atari/image/fuel.png',cv2.IMREAD_UNCHANGED)
jet = cv2.imread('C:/Users/soolim/Desktop/coding/LAB/atari/image/jet.png',cv2.IMREAD_UNCHANGED)
bridge = cv2.imread('C:/Users/soolim/Desktop/coding/LAB/atari/image/bridge.png',cv2.IMREAD_UNCHANGED)


# start = 0, system = 1, quit =2 
current_screen = 0
current_list = 0
current_main = 0
key_setting = 0
action = 0

cv2.namedWindow('ATARI')
cv2.imshow('ATARI',image_start)
        

while True:
    for event in pygame.event.get():  
        
        if event.type == pygame.QUIT: 
            break
        
        elif event.type == pygame.JOYHATMOTION:
            if event.hat == 0:
                if event.value == (0,-1):

                    if current_main == 0:
                        if current_screen == 0:
                            current_screen = 1
                            cv2.imshow('ATARI',image_system)

                        elif current_screen == 1:
                            current_screen = 2
                            cv2.imshow('ATARI',image_quit)
                    
                        elif current_screen == 2:
                            current_screen = 0
                            cv2.imshow('ATARI',image_start)

                    elif current_main == 1:
                        if current_list == 0 :
                            current_list = 1
                            cv2.imshow('LIST',image_list2)
                    
                        elif current_list == 1:
                            current_list = 2
                            cv2.imshow('LIST',image_list3)
                    
                        elif current_list == 2:
                            current_list = 3
                            cv2.imshow('LIST',image_list4) 
                    
                        elif current_list == 3: 
                            current_list = 0
                            cv2.imshow('LIST',image_list1)

        elif current_main == 0:
            if current_screen == 0: 
                if joystick.get_button(0) :
                    #cv2.destroyAllWindows()
                    cv2.destroyWindow('ATARI')
                    cv2.namedWindow('LIST')
                    cv2.imshow('LIST',image_list1)
                    current_main = 1
                    

            elif current_screen == 1:
                if joystick.get_button(0) :
                    cv2.destroyWindow('ATARI')
                    cv2.imshow('SYSTEM',image_system_)
                    current_main = 2
                    
            elif current_screen == 2:
                if joystick.get_button(0):
                    cv2.destroyAllWindows()
                    break
                       
        elif current_main == 1 :
            if current_list == 0:
                if joystick.get_button(0):
                    cv2.destroyWindow('LIST')
                    current_main = 3

                elif joystick.get_button(2):
                    cv2.destroyWindow('LIST')
                    cv2.imshow('ATARI',image_start)
                    current_main = 0
                    current_scrren = 0

            elif current_list == 1:
                if joystick.get_button(0):
                    cv2.destroyWindow('LIST')
                    mapping = {(pygame.K_SPACE,): 1,(pygame.K_LEFT,): 4, (pygame.K_RIGHT,): 3}
                    play(gym.make("Ailen-v4"), keys_to_action=mapping,zoom=3)
            
            elif current_list == 2:
                if joystick.get_button(0):
                    cv2.destroyWindow('LIST')
                    mapping = {(pygame.K_SPACE,): 1,(pygame.K_LEFT,): 4, (pygame.K_RIGHT,): 3}
                    play(gym.make("Berzerk-v4"), keys_to_action=mapping,zoom=3)

            elif current_list == 3:
                if joystick.get_button(0):
                    cv2.destroyWindow('LIST')
                    mapping = {(pygame.K_SPACE,): 1,(pygame.K_LEFT,): 4, (pygame.K_RIGHT,): 3}
                    play(gym.make("Frostbite-v4"), keys_to_action=mapping,zoom=3)

            

            
                    

        elif current_main == 2:
            if joystick.get_button(1):
                key_setting = 1
                print('Keyboard')
            elif joystick.get_button(3):
                key_setting = 0
                print('Joystick')
            elif joystick.get_button(2):
                cv2.destroyWindow('SYSTEM')
                cv2.imshow('ATARI',image_start)
                current_main = 0

        elif current_main == 3:                
            if key_setting == 0 :
                
                env = gym.make("Riverraid-v4")
                cv2.namedWindow('GAME')
                
                env.reset()
                cv2.imshow('GAME',env.reset())                       
                action=0
                
                while True:
                    key = cv2.waitKey(50)

                    for event in pygame.event.get():

                        obs, reward, done, info = env.step(action)

                        if event.type == pygame.QUIT: 
                            break

                        # elif joystick.get_button(2):
                        #     input('Press BUTTON2 to restart.')

                        #     if joystick.get_button(2):
                                

                        elif joystick.get_button(4):
                            key == 0x700000
                            
                            action = 13
                        elif joystick.get_button(1):
                            key == 0x260000
                                
                            action = 11
                        elif joystick.get_button(3):
                            key == 0x270000
                                
                            action = 12

                        
                        
                    obs, reward, done, info = env.step(action)
                    
                    obs = cv2.resize(obs,(540,700))
                    obs = cv2.cvtColor(obs, cv2.COLOR_BGR2RGB)
                    # b, g, r = cv2.split(obs)
                    # tanker_image = cv2.merge([b, g, r, tanker])

                    cv2.imshow('GAME',obs)

                    if reward == 30:
                        alpha = tanker[:,:,3:]/255.0
                        backgraound_alpha = 1.0 - alpha
                        x1 = 0
                        y1 = 0
                        x2 = x1 + 540
                        y2 = y1 + 700
                        obs[y1:y2,x1:x2] = (alpha * tanker[:,:,:3])+(backgraound_alpha * obs[y1:y2,x1:x2])
                        cv2.imshow('GAME',obs)
                        cv2.waitKey(50)
                        print('+30')
                    elif reward == 60:
                        alpha = helicopter[:,:,3:]/255.0
                        backgraound_alpha = 1.0 - alpha
                        x1 = 0
                        y1 = 0
                        x2 = x1 + 540
                        y2 = y1 + 700
                        obs[y1:y2,x1:x2] = (alpha * helicopter[:,:,:3])+(backgraound_alpha * obs[y1:y2,x1:x2])
                        cv2.imshow('GAME',obs)
                        cv2.waitKey(50)
                        print('+60')
                    elif reward == 80:
                        alpha = fuel[:,:,3:]/255.0
                        backgraound_alpha = 1.0 - alpha
                        x1 = 0
                        y1 = 0
                        x2 = x1 + 540
                        y2 = y1 + 700
                        obs[y1:y2,x1:x2] = (alpha * fuel[:,:,:3])+(backgraound_alpha * obs[y1:y2,x1:x2])
                        cv2.imshow('GAME',obs)
                        cv2.waitKey(50)
                        print('+80')
                    elif reward == 100:
                        alpha = jet[:,:,3:]/255.0
                        backgraound_alpha = 1.0 - alpha
                        x1 = 0
                        y1 = 0
                        x2 = x1 + 540
                        y2 = y1 + 700
                        obs[y1:y2,x1:x2] = (alpha * jet[:,:,:3])+(backgraound_alpha * obs[y1:y2,x1:x2])
                        cv2.imshow('GAME',obs)
                        cv2.waitKey(50)
                        print('+100')
                    elif reward == 500:
                        alpha = bridge[:,:,3:]/255.0
                        backgraound_alpha = 1.0 - alpha
                        x1 = 0
                        y1 = 0
                        x2 = x1 + 540
                        y2 = y1 + 700
                        obs[y1:y2,x1:x2] = (alpha * bridge[:,:,:3])+(backgraound_alpha * obs[y1:y2,x1:x2])
                        cv2.imshow('GAME',obs)
                        cv2.waitKey(50)
                        print('+500')
                    # print('env.action_space :', env.action_space)
                    # print(env.step(action))
                    
                    env.close()


            elif key_setting == 1 :
                mapping = {(pygame.K_SPACE,): 13, (pygame.K_LEFT,): 12, (pygame.K_RIGHT,): 11}                        
                play(gym.make("Riverraid-v4"), keys_to_action=mapping,zoom=3)


