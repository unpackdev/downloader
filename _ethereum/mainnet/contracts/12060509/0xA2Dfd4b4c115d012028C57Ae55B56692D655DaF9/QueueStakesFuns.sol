// pragma solidity 0.7.0;
// // SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

struct QueueStakes {
    UserStake[] items;
    uint256 head;
    uint256 tail;
    uint256 used;
    uint256 length;
}

struct UserStake {
    address user;
    uint256 amount;
    uint256 perRate;
}



library QueueStakesFuns {
   
    function create(QueueStakes storage self, uint256 size) internal {
        self.head = 0;
        self.tail = 0;
        self.used = 0;
        self.length = size;
    }
    
    function append(QueueStakes storage self, UserStake memory item) internal
    returns (uint256 result) {

        require(self.used < self.length, "Arrays out of length");

        self.tail = (self.tail + 1) % self.length;
        uint256 index = (self.tail -1) % self.length;

        if(self.items.length == self.length) {
            self.items[index] = item;
        }else {
            self.items.push(item);
        }

        self.used++;
        return index;
    }
    
    function remove(QueueStakes storage self) internal 
    returns (UserStake memory item, bool result) {
       if (self.used > 0) {
            item = self.items[self.head];
            self.head = (self.head + 1) % self.length;
            self.used--;
            result = true;
        }
    }

    function first(QueueStakes storage self) internal 
    returns (UserStake storage item) {
        require(self.used > 0, "Empty data");
        item = self.items[self.head];
    }

    function indexOf(QueueStakes storage self, uint256 _index) internal returns (UserStake storage item) {
        item = self.items[_index % self.length];
    }

    function indexOfView(QueueStakes storage self, uint256 _index) internal view returns (UserStake memory item) {
        item = self.items[_index % self.length];
    }

}