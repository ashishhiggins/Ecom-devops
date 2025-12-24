package com.app.ecom.service;

import com.app.ecom.entity.User;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class UserService {

    private List<User> userList = new ArrayList<>();

    private Long id = 1L;

    public List<User> getAllUsers(){
        return userList;
    }

    public List<User> createUser(User user){

        user.setId(id++);

        userList.add(user);
        return userList;
    }

}
