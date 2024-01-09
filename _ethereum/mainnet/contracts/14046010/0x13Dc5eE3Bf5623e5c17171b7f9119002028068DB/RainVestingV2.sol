// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";

contract RainVestingV2 is Ownable, EIP712 {
    using SafeERC20 for IERC20;

    event Released(address beneficiary, uint256 amount);

    IERC20 public token;
    uint256 public lockupTime;
    uint256 public percentUpfront;
    uint256 public start;
    uint256 public duration;

    mapping(address => uint256) public tokenAmounts;
    mapping(address => uint256) public lastReleaseDate;
    mapping(address => uint256) public releasedAmount;

    address public immutable cSigner;

    uint256 private released;
    uint256 private BP = 1000000;

    address[] public beneficiaries;

    modifier onlyBeneficiaries() {
        require(
            msg.sender == owner() || tokenAmounts[msg.sender] > 0,
            "You cannot release tokens!"
        );
        _;
    }

    bytes32 public constant SIGNED_MESSAGE =
        keccak256(abi.encodePacked("User(address beneficiary,uint256 amount)"));

    constructor(
        IERC20 _token,
        uint256 _start,
        uint256 _lockupTime,
        uint256 _percentUpfront,
        uint256 _duration,
        address _signer
    ) EIP712("Rainmaker", "1") {
        require(
            _lockupTime <= _duration,
            "Cliff has to be lower or equal to duration"
        );
        cSigner = _signer;
        token = _token;
        duration = _duration;
        lockupTime = _start + _lockupTime;
        percentUpfront = _percentUpfront;
        start = _start;
    }

    function addBeneficiary(
        address _beneficiary,
        uint256 _tokenAmount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(
            tokenAmounts[_beneficiary] == 0,
            "Rainmaker: User already added"
        );
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparatorV4(),
                keccak256(
                    abi.encode(SIGNED_MESSAGE, _beneficiary, _tokenAmount)
                )
            )
        );
        require(
            ecrecover(digest, v, r, s) == cSigner,
            "Rainmaker: Invalid signer"
        );

        require(
            block.timestamp < lockupTime ||
                (lockupTime == start && block.timestamp < start + 32 days),
            "Invalid timing"
        );
        require(
            _beneficiary != address(0),
            "The beneficiary's address cannot be 0"
        );
        require(_tokenAmount > 0, "Amount has to be greater than 0");

        beneficiaries.push(_beneficiary);

        lastReleaseDate[_beneficiary] = lockupTime;
        tokenAmounts[_beneficiary] = _tokenAmount;
    }

    function claimTokens() public onlyBeneficiaries {
        require(
            releasedAmount[msg.sender] < tokenAmounts[msg.sender],
            "User already released all available tokens"
        );

        uint256 unreleased = releasableAmount(msg.sender) - releasedAmount[msg.sender];

        if (unreleased > 0) {
            released += unreleased;
            release(msg.sender, unreleased);
            lastReleaseDate[msg.sender] = block.timestamp;
        }
    }

    function userReleasableAmount(address _account) public view returns (uint256) {
        return releasableAmount(_account);
    }

    function releasableAmount(address _account) private view returns (uint256) {
        if (block.timestamp < lockupTime) {
            return 0;
        } else {
            uint256 result;

            if (percentUpfront > 0 && block.timestamp >= lockupTime) {
                result += (tokenAmounts[_account] * percentUpfront) / BP;
            }

            if (block.timestamp < lastReleaseDate[_account]) return 0;
            uint256 timePassed = block.timestamp - lockupTime;
            
            if (timePassed <= duration - (lockupTime - start)) {
                result +=
                    tokenAmounts[_account] * timePassed / duration;
            } else {
                result += tokenAmounts[_account];
            }

            return result;
        }
    }

    function totalAmounts() public view returns (uint256 sum) {
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            sum += tokenAmounts[beneficiaries[i]];
        }
    }

    function release(address _beneficiary, uint256 _amount) private {
        token.safeTransfer(_beneficiary, _amount);
        releasedAmount[_beneficiary] += _amount;
        emit Released(_beneficiary, _amount);
    }

    function withdraw(IERC20 _token) external onlyOwner {
        if (_token == IERC20(address(0))) {
            // allow to rescue ether
            payable(owner()).transfer(address(this).balance);
        } else {
            uint256 withdrawAmount = _token.balanceOf(address(this));
            if (withdrawAmount > 0) {
                _token.safeTransfer(address(msg.sender), withdrawAmount);
            }
        }
    }
}
