// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Narwhal.sol";
import "./NarwhallousSubmission.sol";
import "./IERC721.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";

contract Narwhallous is AccessControlEnumerable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    struct AwardInfo {
        address receiver;
        uint256 tokenId;
        address implementation;
    }

    Counters.Counter private _sharesPaid;
    Counters.Counter private _awardsGiven;
    mapping(string => uint256) private _submissionPays;
    mapping(address => uint256) private _userDividends;
    mapping(address => AwardInfo[]) private _userAwards;
    mapping(address => AwardInfo[]) private _implAwards;
    string private constant INVALID_PERMISSION = "Invalid permissions";
    bytes32 public constant WITHDRAWAL_ROLE = keccak256("WITHDRAWAL_ROLE");

    uint256 public _preferedShares = 1; // default is 1, so total 10 shares
    uint256 public _submitShares = 9; // default is 9, so total 10 shares
    uint256 public _submitFee = 400000000000000000; // default is 400000000000000000

    bool public paused = false;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(WITHDRAWAL_ROLE, _msgSender());
    }

    /**
     * @dev Returns the required submit fee, if you do not want to mint but want to pay instead
     */
    function requiredSubmitFee() view public returns (uint256) {
        return _submitFee;
    }

    /**
     * @dev Returns the required premint amount that would need to be minted by this contract to submit
     */
    function requiredSubmitShares() view public returns (uint256) {
        return _submitShares;
    }

    /**
     * @dev Puts the contract into either paused or unpause state
     */
    function flipPauseState() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), INVALID_PERMISSION);
        paused = !paused;
    }

    /**
     * @dev Updates the required submit fee, only admins can execute
     */
    function setSubmitFee(uint256 amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), INVALID_PERMISSION);
        _submitFee = amount;
    }

    /**
     * @dev Updates prefered shares amount (these shares always get a dividend), only admins can execute
     */
    function setPreferedShares(uint256 amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), INVALID_PERMISSION);
        _preferedShares = amount;
    }

    /**
     * @dev Updates the share amount submit fee, only admins can execute
     */
    function setSubmitShares(uint256 amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), INVALID_PERMISSION);
        _submitShares = amount;
    }

    /**
     * @dev Withdraw any ether that may have been sent to the contract itself (mostly from prefered shares)
     */
    function withdraw(address payable to, uint256 amount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), INVALID_PERMISSION);
        require(
            hasRole(WITHDRAWAL_ROLE, to),
            "Adress we are sending to must have WITHDRAWAL role, this is to avoid typos"
        );
        uint256 balance = address(this).balance;
        require(
            amount <= balance,
            "Withdraw would exceed amount available in balance"
        );
        to.transfer(amount);
    }

    /**
     * @dev Generated random int between min and max, with the seed from the current block
     * Best we can without a RNG Oracle providing real random
     */
    function _random(uint256 min, uint256 max) private view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number
                )
            )
        );

        return (seed - ((seed / max) * max)) + min;
    }

    function awardedTotal() public view returns (uint256) {
        return _awardsGiven.current();
    }

    function awardedByAddress(address owner) public view returns (uint256) {
        return _userAwards[owner].length;
    }

    function paidBySubmission(string memory uid)
        public
        view
        returns (uint256)
    {
        return _submissionPays[uid];
    }

    function awardedByNFT(address implementation)
        public
        view
        returns (uint256)
    {
        return _implAwards[implementation].length;
    }

    function awardsByAddress(address owner)
        public
        view
        returns (AwardInfo[] memory)
    {
        uint256 balance = _userAwards[owner].length;
        AwardInfo[] memory awards = new AwardInfo[](balance);
        for (uint256 i = 0; i < balance; i++) {
            awards[i] = _userAwards[owner][i];
        }
        return awards;
    }

    function awardsByNFT(address implementation)
        public
        view
        returns (AwardInfo[] memory)
    {
        uint256 balance = _implAwards[implementation].length;
        AwardInfo[] memory awards = new AwardInfo[](balance);
        for (uint256 i = 0; i < balance; i++) {
            awards[i] = _implAwards[implementation][i];
        }
        return awards;
    }

    function payToWin(
        address payable addr,
        string memory uid
    ) public payable {
        Narwhal narwhalContract = Narwhal(addr);
        require(paused == true, "Submission is paused");
        if (paidBySubmission(uid) >= _submitFee) {
            revert("Already payed the required amount to publish!");
        }
        require(
            _submitFee <= msg.value,
            "Ether value sent is not correct"
        );
        uint256 dividend = msg.value.div(_submitShares.add(_preferedShares));
        uint256 totalSupply = narwhalContract.totalSupply();
        uint256 remainingShares = _submitShares;
        _submissionPays[uid] = msg.value.add(_submissionPays[uid]);
        for (uint256 i = 0; i < _submitShares; i++) {
            uint256 randomTokenId = _random(0, totalSupply);
            address randomOwner = narwhalContract.ownerOf(randomTokenId);
            payable(randomOwner).transfer(dividend);
            remainingShares = remainingShares.sub(1);
        }
        payable(this).transfer(dividend.mul(_preferedShares.add(remainingShares)));
    }

    function mintToWin(
        address payable addr,
        address impl
    ) public {
        Narwhal narwhalContract = Narwhal(addr);
        INarwhallousSubmission implementation = INarwhallousSubmission(impl);
        require(paused == true, "Submission is paused");
        uint256 balance = awardedByNFT(impl);
        if (balance >= _submitShares) {
            revert("Already awarded the required amount to publish!");
        }
        uint256 totalSupply = narwhalContract.totalSupply();
        uint256 amountToMint = _submitShares - balance;
        AwardInfo memory info;
        for (uint256 i = 0; i < amountToMint; i++) {
            uint256 randomTokenId = _random(0, totalSupply);
            address randomOwner = narwhalContract.ownerOf(randomTokenId);
            uint256 tokenId = implementation.memberMint(randomOwner);
            info = AwardInfo(randomOwner, tokenId, impl);
            _userAwards[randomOwner].push(info);
            _userAwards[impl].push(info);
            _awardsGiven.increment();
        }
    }

    fallback() external payable {}
    receive() external payable {}
}
