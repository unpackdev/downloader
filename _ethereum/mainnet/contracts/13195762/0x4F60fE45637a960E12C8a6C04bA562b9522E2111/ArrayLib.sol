// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.8.0;

library ArrayLib {

    string constant NOT_IN_ARRAY     = "Not in array";
    string constant ALREADY_IN_ARRAY = "Already in array";

    // address array

    function inArray(address[] storage array, address _item)
    internal view returns (bool) {
        uint len = array.length;
        for (uint i=0; i<len; i++) {
            if (array[i]==_item) return true;
        }
        return false;
    }

    function addUnique(address[] storage array, address _item)
    internal {
        require(!inArray(array, _item), ALREADY_IN_ARRAY);
        array.push(_item);
    }

    function removeByIndex(address[] storage array, uint256 index)
    internal {
        uint256 len_1 = array.length - 1;
        require(index<=len_1, NOT_IN_ARRAY);
        for (uint256 i = index; i < len_1; i++) {
            array[i] = array[i + 1];
        }
        array.pop();
    }

    function removeFirst(address[] storage array, address _item)
    internal {
        require(inArray(array, _item), NOT_IN_ARRAY);
        uint last = array.length-1;
        for (uint i=0; i<=last; i++) {
            if (array[i]==_item) {
                removeByIndex(array, i);
                return;
            }
        }
    }

    function addArrayUnique(address[] storage array, address[] memory _items)
    internal {
        uint len = _items.length;
        for (uint i=0; i<len; i++) {
            addUnique(array, _items[i]);
        }
    }

    function removeArrayFirst(address[] storage array, address[] memory _items)
    internal {
        uint len = _items.length;
        for (uint i=0; i<len; i++) {
            removeFirst(array, _items[i]);
        }
    }

    function inArray(uint256[] storage array, uint256 _item)
    internal view returns (bool) {
        uint len = array.length;
        for (uint i=0; i<len; i++) {
            if (array[i]==_item) return true;
        }
        return false;
    }

    function addUnique(uint256[] storage array, uint256 _item)
    internal {
        require(!inArray(array, _item), ALREADY_IN_ARRAY);
        array.push(_item);
    }


    function removeByIndex(uint256[] storage array, uint256 index)
    internal {
        uint256 len_1 = array.length - 1;
        require(index<=len_1, NOT_IN_ARRAY);
        for (uint256 i = index; i < len_1; i++) {
            array[i] = array[i + 1];
        }
        array.pop();
    }

    function removeFirst(uint256[] storage array, uint256 _item)
    internal {
        require(inArray(array, _item), NOT_IN_ARRAY);
        uint last = array.length-1;
        for (uint i=0; i<=last; i++) {
            if (array[i]==_item) {
                removeByIndex(array, i);
                return;
            }
        }
    }

    function addArrayUnique(uint256[] storage array, uint256[] memory _items)
    internal {
        uint len = _items.length;
        for (uint i=0; i<len; i++) {
            addUnique(array, _items[i]);
        }
    }

    function removeArrayFirst(uint256[] storage array, uint256[] memory _items)
    internal {
        uint len = _items.length;
        for (uint i=0; i<len; i++) {
            removeFirst(array, _items[i]);
        }
    }

}
