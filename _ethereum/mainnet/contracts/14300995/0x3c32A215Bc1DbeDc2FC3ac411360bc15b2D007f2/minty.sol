// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";


contract LFGLoot is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address payable lfgLootAddr = payable(0x19E450E951067Fc3D43b346D099a84f69aE00c29);
    address constant teamNFTAddr = 0xC9EaBb1bf69543E4f5D681431B26032e0b778237;
    uint256 private whiteListNum = 1400;
    uint256 private commonUserNum = 3400;
    uint256 private teamUserNum = 199;
    mapping(address => uint256) private whiteListUser;
    string public baseUrl;
    address public owner;

    event TokenIDs(address to, uint256 token);

    constructor()
    ERC721("LFGLoot", "LFG")
    {
        // set owner
        owner = msg.sender;
        // initial base url
        baseUrl = "https://gateway.pinata.cloud/ipfs/QmPrfCwssXpEK3yDgiAYzFSyPWc5iqyrfj97SJbStkR3CJ/";
        // mint team NFT
        for (uint i = 0; i < teamUserNum; i++) {
            uint256 newItemId = genTokenId();
            _safeMint(teamNFTAddr, newItemId);
        }
    }

    modifier onlyOwner {
        require(msg.sender == owner, "msg.sender != owner");
        _;
    }

    function setBaseURI(string memory url)
    external
    onlyOwner
    {
        baseUrl = url;
    }

    function _baseURI()
    internal
    view
    virtual
    override
    returns (string memory)
    {
        return baseUrl;
    }

    function setWhiteListUser(address to, uint256 num)
    private
    {
        whiteListUser[to] = num;
    }

    function getWhiteMintedNum(address to)
    private
    view
    returns (uint256 num)
    {
        if (whiteListUser[to] <= 0) {
            return 0;
        }
        return whiteListUser[to];
    }

    function uint2bytes(uint256 _i)
    internal
    pure
    returns (bytes memory)
    {
        if (_i == 0)
        {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0)
        {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0)
        {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }

        return bstr;
    }

    function recover(bytes32 hash, bytes memory sig)
    internal
    pure
    returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        //Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }

    function mintedNumber()
    public
    view
    returns (uint256) {
        uint256 curMinted = _tokenIds.current();
        return curMinted;
    }

    function totalSupply()
    public
    pure
    returns (uint256)
    {
        return 4999;
    }

    function inWhiteList(uint256 num, uint256 timestamp, bytes32 hash, bytes memory sign)
    private
    view
    returns (bool)
    {
        address backendSignAddr = 0x9f7475A7A5b3f4441cce22f3A39213c7Da3B9445;
        
        require(timestamp + 300 > block.timestamp);

        bytes memory numByte = uint2bytes(num);
        bytes memory timeByte = uint2bytes(timestamp);
        address to = msg.sender;
        bytes memory s = abi.encodePacked(numByte, timeByte, to);

        bytes32 genHash = keccak256(s);
        if (genHash != hash) {
            return false;
        }
        address addr = recover(hash, sign);
        return addr == backendSignAddr;
    }

    function genTokenId()
    private
    returns (uint256)
    {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        return newItemId;
    }

    function mintLFG(uint256 num, uint256 timestamp, bytes32 hash, bytes memory sign)
    // function mintLFG(uint256 num)
    public
    payable
    {
        uint256 commonPrice = 9 * (10 ** 16);
        uint256 whiteListPrice = 7 * (10 ** 16);
        
        require(mintedNumber() < totalSupply(), "mintedNumber < totalSupply");
        uint256 maxNum;
        uint256 amount;
        // current user
        address to = msg.sender;
        
        bool isWhiteListUser = inWhiteList(num, timestamp, hash, sign);
        // bool isWhiteListUser = false;
        if (isWhiteListUser) {
            maxNum = 2;
            
            require(getWhiteMintedNum(to) < maxNum, "getWhiteMintedNum < maxNum");
            
            require(whiteListNum > num, "whiteListNum > num");
            
            require(num <= maxNum, "num <= maxNum");
            amount = whiteListPrice * num;
            
            whiteListNum -= num;
            
            setWhiteListUser(to, num);
        } else {
            
            maxNum = 5;
            require(num < maxNum, "num < maxNum");
            amount = commonPrice * num;

            require(commonUserNum > num, "commonUserNum < num");
            
            commonUserNum -= num;
        }

        // require(msg.sender.balance > amount);
        require(msg.value >= amount, "msg.value > amount");
        // payable(lfgLootAddr).transfer(msg.value);
        lfgLootAddr.transfer(msg.value);

        for (uint i = 0; i < num; i++) {
            uint256 newItemId = genTokenId();
            _safeMint(to, newItemId);
            emit TokenIDs(to, newItemId);
        }
    }
}
