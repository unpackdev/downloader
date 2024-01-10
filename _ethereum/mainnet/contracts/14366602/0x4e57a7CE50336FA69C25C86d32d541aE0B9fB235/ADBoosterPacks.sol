//SPDX-License-Identifier: MIT
/*
-- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- -- -- - -- - -- - -- - -- - -- - -- - --
-  ______     __   __     ______     __  __     _____     ______     __    __     __     ______     __   __     -
- /\  __ \   /\ "-.\ \   /\  ___\   /\ \/ /    /\  __-.  /\  __ \   /\ "-./  \   /\ \   /\  __ \   /\ "-.\ \    -
- \ \  __ \  \ \ \-.  \  \ \  __\   \ \  _"-.  \ \ \/\ \ \ \  __ \  \ \ \-./\ \  \ \ \  \ \  __ \  \ \ \-.  \   -
-  \ \_\ \_\  \ \_\\"\_\  \ \_____\  \ \_\ \_\  \ \____-  \ \_\ \_\  \ \_\ \ \_\  \ \_\  \ \_\ \_\  \ \_\\"\_\  -
-   \/_/\/_/   \/_/ \/_/   \/_____/   \/_/\/_/   \/____/   \/_/\/_/   \/_/  \/_/   \/_/   \/_/\/_/   \/_/ \/_/  -
-                                                                                                               -    
-- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- -- -- - -- - -- - -- - -- - -- - -- - --


*/
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";

interface IADToken {
    function mint(uint256, address) external;
}

contract ADBoosterPacks is Ownable, ReentrancyGuard {
    IADToken private adTrainers;
    IADToken private adElementals;
    address public signerAddress;
    uint256 public constant tokenPrice = 0.0777 ether;
    uint256 public constant MAX_SUPPLY = 7770;
    uint256 public constant MAX_RESERVED = 100;
    uint256 public totalSupply = 0;
    uint256 public publicMintPerTxLimit = 2;
    uint256 public reserved;

    bool public allowListMintActive;
    bool public publicMintActive;

    mapping(address => uint256) public presaleMinted;

    modifier callerIsUser() {
        require(msg.sender == tx.origin, "Failed EOA check");
        _;
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============

    function setTokenAddresses(
        address _adElementalAddress,
        address _adTrainerAddress
    ) external onlyOwner {
        adElementals = IADToken(_adElementalAddress);
        adTrainers = IADToken(_adTrainerAddress);
    }

    function setPublicMintPerTxLimit(uint256 _limit) external onlyOwner {
        publicMintPerTxLimit = _limit;
    }

    function setPublicMintActive(bool val) public onlyOwner {
        publicMintActive = val;
    }

    function setAllowListMintActive(bool val) public onlyOwner {
        allowListMintActive = val;
    }

    function setSignerAddress(address _signerAddress) external onlyOwner {
        signerAddress = _signerAddress;
    }

    function withdrawAll() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(owner(), address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed");
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============

    function mintPublic(uint256 _amount)
        external
        payable
        callerIsUser
        nonReentrant
    {
        require(publicMintActive, "Public mint has not started");
        require(
            _amount <= publicMintPerTxLimit,
            "Exceeded public mint per tx limit"
        );

        unchecked {
            uint256 supply = totalSupply;
            require(supply + _amount <= MAX_SUPPLY, "Exceeded max supply");
            totalSupply = supply + _amount;

            require(msg.value == _amount * tokenPrice, "Invalid amount of ETH");
        }

        _mint(_amount, msg.sender);
    }

    function mintAllowList(
        uint256 _amount,
        bytes memory _signature,
        uint256 _eligibleAmount
    ) external payable callerIsUser nonReentrant {
        require(allowListMintActive, "Allowlist mint has not started");
        require(
            verifySignature(
                keccak256(abi.encodePacked(msg.sender, _eligibleAmount)),
                _signature
            ),
            "Invalid signature"
        );
        require(
            _amount <= _eligibleAmount,
            "Mint amount exceeds eligible amount"
        );

        unchecked {
            uint256 minted = presaleMinted[msg.sender];
            require(
                minted + _amount <= _eligibleAmount,
                "Exceeded alowlist mint limit"
            );
            presaleMinted[msg.sender] = minted + _amount;

            uint256 supply = totalSupply;
            require(supply + _amount <= MAX_SUPPLY, "Exceeded max supply");
            totalSupply = supply + _amount;

            require(msg.value == _amount * tokenPrice, "Invalid amount of ETH");
        }

        _mint(_amount, msg.sender);
    }

    function reserve(uint256 _amount, address _to)
        external
        nonReentrant
        onlyOwner
    {
        unchecked {
            require(
                reserved + _amount <= MAX_RESERVED,
                "Exceeds maximum number of reserved tokens"
            );
            require(totalSupply + _amount <= MAX_SUPPLY, "Insufficient supply");
            totalSupply += _amount;
            reserved += _amount;
        }

        _mint(_amount, _to);
    }

    // ============ INTERNAL UTIL FUNCTIONS ============

    function _mint(uint256 _amount, address _to) private {
        adTrainers.mint(_amount, _to);
        adElementals.mint(_amount, _to);
    }

    function verifySignature(bytes32 _hash, bytes memory _signature)
        internal
        view
        returns (bool)
    {
        address recoveredAddress = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(_hash),
            _signature
        );
        return (recoveredAddress != address(0) &&
            recoveredAddress == signerAddress);
    }
}
