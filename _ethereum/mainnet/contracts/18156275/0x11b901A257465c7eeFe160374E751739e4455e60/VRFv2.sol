// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ConfirmedOwner.sol";
import "./VRFV2WrapperConsumerBase.sol";
import "./AccessControl.sol";
import "./IPixelNFTMinter.sol";

contract VRFv2 is
    VRFV2WrapperConsumerBase,
    ConfirmedOwner,
    AccessControl
{
    bytes32 public constant REQUEST_ROLE = keccak256("REQUEST_ROLE");
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(
        uint256 requestId,
        uint256[] randomWords,
        uint256 payment
    );

    struct RequestStatus {
        uint256 paid; // amount paid in link
        bool fulfilled; // whether the request has been successfully fulfilled
        uint256[] randomWords;
        address minter;
    }

    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    uint32 public callbackGasLimit = 200000;

    uint16 public requestConfirmations = 3;

    uint32 public numWords = 1;
    address public linkAddress;
    address public wrapperAddress;

    constructor(
      address _linkAddress,
      address _wrapperAddress
    )
        ConfirmedOwner(msg.sender)
        VRFV2WrapperConsumerBase(_linkAddress, _wrapperAddress)
    {
      linkAddress = _linkAddress;
      wrapperAddress = _wrapperAddress;
      _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
      _grantRole(REQUEST_ROLE, msg.sender);
    }

    function requestRandomWords()
        external
        onlyRole(REQUEST_ROLE)
        returns (uint256 requestId)
    {
        requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            randomWords: new uint256[](0),
            fulfilled: false,
            minter: msg.sender
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].paid > 0, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        require(
            IPixelNFTMinter(
                s_requests[_requestId].minter
            ).awardToWinner(
                _requestId,
                _randomWords[0]
            ),
            'VRF2: Unable to award prize to the winner'
        );
        emit RequestFulfilled(
            _requestId,
            _randomWords,
            s_requests[_requestId].paid
        );
    }

    function getRequestStatus(
        uint256 _requestId
    )
        external
        view
        returns (uint256 paid, bool fulfilled, uint256[] memory randomWords, address minter)
    {
        require(s_requests[_requestId].paid > 0, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.paid, request.fulfilled, request.randomWords, request.minter);
    }

    function updateCallbackGasLimit(uint32 _gasLimit) public onlyOwner {
      callbackGasLimit = _gasLimit;
    }

    function updateRequestConfirmations(uint16 _confirmations) public onlyOwner {
      requestConfirmations = _confirmations;
    }

    function updateNumWords(uint32 _numWords) public onlyOwner {
      numWords = _numWords;
    }

    function updateLinkAddress(address _newAddress) public onlyOwner {
      linkAddress = _newAddress;
    }

    function updateWrapperAddress(address _newAddress) public onlyOwner {
      wrapperAddress = _newAddress;
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
}
