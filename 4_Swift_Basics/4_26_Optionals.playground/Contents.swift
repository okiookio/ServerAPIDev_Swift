//: Playground - noun: a place where people can play

//Important takeaways:
//Use optional ? when you are not sure if the variable will have a value. You will need to unwrap these variables.
//Use an implicitly unwrapped optional when you are sure that the variable will have a value at some point, but not when the class is initialized. Make sure that you accompany this kind of variable with safety code like a getter.
//Use a regular variable when you are assigning a value right away, or in the initializer.

import UIKit

class Car {
    var model: String?
}

var vehicle: Car?

vehicle = Car()
vehicle?.model = "Focus"
//only use code like this above, if you don't care whether it executes or not. In this case, the model won't be set if the vehicle is nil.

if let v = vehicle, let m = v.model {
    print(m)
}




var cars: [Car]?

cars = [Car]()

if let vehicle = vehicle {
    cars?.append(vehicle)
}

if let carArr = cars, carArr.count > 0 {
    print("I have cars")
}


//The bang symbol means that the variable works exactly the same as an optional except the compiler won't require you to unwrap it. If you use an implicitly unwrapped optional, you need to be super-careful to set it in an initializer. You may also consider giving it a default value.

//Here is a common technique for setting a default value, if the variable has nothing in it. There is a private variable which holds the actual value and then a publicly accessible computed variable that tests if there is a value or not using a getter method. Finally, we need a function to set the privately facing variable.

class Person {
    
    private var _age: Int!
    
    var age: Int {
        get {
            if _age == nil {
                _age = 0
            }
            return _age
        }
    }
    
    func setAge(_ age: Int) {
        _age = age
    }
}


let newPerson = Person()
newPerson.age


newPerson.setAge(32)
newPerson.age


//If you don't use an optional, but don't set an initial value for your variable, you will need to deal with it in the initializer.

class Dog {
    
    var breed: String
    
    init(breed: String) {
        self.breed = breed
    }
    
}

var dog1 = Dog(breed: "labrador")
dog1.breed




