// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";

abstract contract AbstractAccessUnitControl is Ownable {
    mapping(address => uint256) private s_mapAccessAllowedAddresses; //holds address and allowed nr of allowed elements to be minted by this address
    address[] private s_addedAddresses; //holds all added addresses
    address s_handshakeContract; //used for feedback of minted tokens

    function linkHandshakeContract(address _handshakeContract)
        public
        virtual
        onlyOwner
    {
        require(_handshakeContract != address(0), "invalid address");
        s_handshakeContract = _handshakeContract;
    }

    function addAddressToAccessAllowed(
        address _addressToBeAdded,
        uint256 _nrOfAllowedElements
    ) public virtual onlyOwner {
        require(_addressToBeAdded != address(0), "invalid address");
        require(_nrOfAllowedElements > 0, "nr of allowed elements <= 0");
        require(
            s_mapAccessAllowedAddresses[_addressToBeAdded] !=
                _nrOfAllowedElements,
            "data already added"
        );
        if (s_mapAccessAllowedAddresses[_addressToBeAdded] == 0) {
            //address not yet added
            s_addedAddresses.push(_addressToBeAdded);
        }
        s_mapAccessAllowedAddresses[_addressToBeAdded] = _nrOfAllowedElements; //set nr of allowed elements to be minted by this address
    }

    function isAccessGranted(address _adressToBeChecked)
        public
        view
        virtual
        returns (bool)
    {
        require(_adressToBeChecked != address(0), "invalid address");
        if (s_mapAccessAllowedAddresses[_adressToBeChecked] > 0) {
            //so this address would be able to mint tokens, now we check if he already did
            require(
                s_handshakeContract != address(0),
                "handshakeContract not set"
            );
            //call other contract functions
            hadshakeContractImpl handshakeContract = hadshakeContractImpl(
                s_handshakeContract
            );
            if (
                handshakeContract.balanceOf(_adressToBeChecked) <
                s_mapAccessAllowedAddresses[_adressToBeChecked]
            ) {
                return (true);
            }
        }
    }

    function getNrOfAllowedElementsPerAddress(address _adressToBeChecked)
        public
        view
        virtual
        returns (uint256)
    {
        return (s_mapAccessAllowedAddresses[_adressToBeChecked]);
    }

    function getRemainingNrOfElementsPerAddress(address _adressToBeChecked)
        public
        view
        virtual
        returns (uint256)
    {
        require(_adressToBeChecked != address(0), "null address given");
        require(
            s_handshakeContract != address(0),
            "handshakecontract unlinked"
        );
        hadshakeContractImpl handshakeContract = hadshakeContractImpl(
            s_handshakeContract
        );
        return (s_mapAccessAllowedAddresses[_adressToBeChecked] -
            handshakeContract.balanceOf(_adressToBeChecked));
    }

    function removeAdressFromMapping(address _adressToBeRemoved)
        public
        virtual
        onlyOwner
    {
        require(_adressToBeRemoved != address(0), "null address given");
        delete s_mapAccessAllowedAddresses[_adressToBeRemoved];
    }

    function getCurrentNrOfElementsInMapping()
        public
        view
        virtual
        returns (uint256)
    {
        return (s_addedAddresses.length);
    }

    function removeAllFromAccessAllowed() public virtual onlyOwner {
        uint256 nrOfDeletesNeeded = s_addedAddresses.length;
        for (uint256 i; i < nrOfDeletesNeeded; i++) {
            removeAddressFromAccessAllowed(s_addedAddresses[0]); //refer always deleting first element, because wer reduce array after this call
        }
        delete s_addedAddresses;
    }

    function removeAddressFromAccessAllowed(address _addressToRemove)
        public
        virtual
        onlyOwner
    {
        require(_addressToRemove != address(0), "null address given");
        require(
            s_mapAccessAllowedAddresses[_addressToRemove] > 0,
            "address not found"
        );
        for (uint256 i; i < s_addedAddresses.length; i++) {
            if (s_addedAddresses[i] == _addressToRemove) {
                removeAdressFromMapping(_addressToRemove); //remove from mapping
                removeAddressByIndex(i);
                break;
            }
        }
    }

    function getArrayOfAddresses()
        public
        view
        virtual
        returns (address[] memory)
    {
        return s_addedAddresses;
    }

    function removeAddressByIndex(uint256 _indexToRemove) private {
        require(
            _indexToRemove <= s_addedAddresses.length ||
                s_addedAddresses.length > 0,
            "index out of range"
        );
        if (_indexToRemove == s_addedAddresses.length - 1) {
            s_addedAddresses.pop();
        } else {
            s_addedAddresses[_indexToRemove] = s_addedAddresses[
                s_addedAddresses.length - 1
            ];
            s_addedAddresses.pop();
        }
    }
}

abstract contract hadshakeContractImpl {
    function balanceOf(address owner) public view virtual returns (uint256);
}
