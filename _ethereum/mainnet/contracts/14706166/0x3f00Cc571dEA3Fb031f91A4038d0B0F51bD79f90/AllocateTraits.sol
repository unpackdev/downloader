pragma solidity 0.8.7;
// SPDX-License-Identifier: GPL-3.0-or-later

import "./Ownable.sol";
import "./Strings.sol";

import "./console.sol";

interface IRNG {
    function requestRandomNumber() external returns (bytes32);
    function requestRandomNumberWithCallback() external returns (bytes32);
    function isRequestComplete(bytes32 requestId) external view returns (bool isCompleted);
    function randomNumber(bytes32 requestId) external view returns (uint256 randomNum);
    function setAuth(address user, bool grant) external;
}

contract AllocateTraits is Ownable {
    using Strings for uint256;

    IRNG public _iRnd;
    bytes32 public _reqID;

    uint256 public _randomCL;
    bool    public _randomReceived;
    string  public metaDataString;
    uint256 public tokenSupply = 1493;

    constructor(IRNG _rng) {
        _iRnd = _rng;
    }

    function requestReveal(
        string calldata revealedBaseURI
    ) external onlyOwner {
        metaDataString = revealedBaseURI;
        _reqID = _iRnd.requestRandomNumberWithCallback();
    }

    function process(uint256 random, bytes32 reqID) external {
        require(msg.sender == address(_iRnd), "RM: Unauthorised RNG");
        if (_reqID == reqID) {
            _randomCL = random / 2; // set msb to zero
            _randomReceived = true;
        } else revert("RM: Incorrect request ID received");
    }

    function tokenURI(uint256 tokenId) public view returns (string memory)
    {
        require((tokenId > 0 && tokenId <= tokenSupply), "Token does not exist");
        string memory revealedBaseURI = metaDataString;

        if (_randomReceived) {
            tokenId = ((tokenId + _randomCL) % tokenSupply + 1);
        }

        string memory folder = (tokenId % 100).toString();
        string memory file = tokenId.toString();
        string memory slash = "/";
        return string(abi.encodePacked(revealedBaseURI, folder, slash, file, ".json"));
    }
    

}
