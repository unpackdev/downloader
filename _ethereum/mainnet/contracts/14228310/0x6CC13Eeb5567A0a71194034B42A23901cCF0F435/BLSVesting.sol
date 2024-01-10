// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";

contract BLSVesting is Ownable, EIP712 {
    using SafeERC20 for IERC20;

    event Released(address beneficiary, uint256 amount);

    IERC20 public immutable token;
    uint256 public immutable tgeTime;
    uint256 public immutable tgePercentage;
    uint256 public immutable cliffTime;
    uint256 public immutable cliffPercentage;
    uint256 public immutable start;
    uint256 public immutable duration;
    uint256 public immutable period;

    mapping (address => uint256) public tokenAmounts;
    mapping (address => uint256) public lastReleaseDate;
    mapping (address => uint256) public releasedAmount;

    uint256 public released = 0;
    uint256 public constant BP = 1e18;
    address public immutable cSigner;

    address[] public beneficiaries;

    bytes32 public constant SIGNED_MESSAGE =
        keccak256(abi.encodePacked("User(address beneficiary,uint256 amount)"));

    constructor(
        IERC20 _token,
        uint256 _start,
        uint256 _tgeTime, // time after vesting start to distribute tge
        uint256 _tgePercentage, // tge % to be distributed at tge time
        uint256 _cliffTime, // time after tge time to distribute cliff
        uint256 _cliffPercentage, // cliff % to be distributed at cliff time
        uint256 _duration, // total vesting duration since the vesting start
        uint256 _period, // slice periods to distribute, 1 month, 3 months, 6 months, 1 year, any time
        address _signer
    ) EIP712("Blocksport", "1") {
        require(_cliffTime <= _duration, "Cliff has to be lower or equal to duration");
        cSigner = _signer;

        token = _token;
        duration = _duration;

        tgeTime = _start + _tgeTime;
        tgePercentage = _tgePercentage;

        cliffTime = tgeTime + _cliffTime;
        cliffPercentage = _cliffPercentage;

        start = _start;
        period = _period;
    }


    function addBeneficiariesWithSign(
        address[] memory _beneficiaries,
        uint256[] memory _tokenAmounts,
        uint8[] memory _v,
        bytes32[] memory _r,
        bytes32[] memory _s
    ) external {
        require(
            _beneficiaries.length == _tokenAmounts.length && 
            _beneficiaries.length == _v.length && 
            _beneficiaries.length == _r.length && 
            _beneficiaries.length == _s.length
            , "Invalid params"
        );
        
        uint256 totalToBeAdded;
        for (uint i = 0; i <_beneficiaries.length; i++) {
            totalToBeAdded += _tokenAmounts[i];
            require(totalToBeAdded <= token.balanceOf(address(this)), "Invalid token amount");

            addBeneficiaryWithSign(_beneficiaries[i], _tokenAmounts[i], _v[i], _r[i], _s[i]);
        }
        require(totalAmounts() <= token.balanceOf(address(this)), "Insufficient token amount"); // could be replaced with a storage variable, totalInVesting
    }

    function addBeneficiaryWithSign(
        address _beneficiary,
        uint256 _tokenAmount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(tokenAmounts[_beneficiary] == 0, "User already added");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparatorV4(),
                keccak256(
                    abi.encode(SIGNED_MESSAGE, _beneficiary, _tokenAmount)
                )
            )
        );
        require(ecrecover(digest, v, r, s) == cSigner, "Invalid signer");

        addBeneficiary(_beneficiary, _tokenAmount);
        require(totalAmounts() <= token.balanceOf(address(this)), "Insufficient token amount");
    }

    function addBeneficiaries(address[] memory _beneficiaries, uint256[] memory _tokenAmounts) public onlyOwner {
        require(_beneficiaries.length == _tokenAmounts.length, "Invalid params");

        uint256 totalToBeAdded;
        for (uint i = 0; i <_beneficiaries.length; i++) {
            totalToBeAdded += _tokenAmounts[i];
            require(totalToBeAdded <= token.balanceOf(address(this)), "Invalid token amount");
            addBeneficiary(_beneficiaries[i], _tokenAmounts[i]);
        }

        require(totalAmounts() <= token.balanceOf(address(this)), "Insufficient token amount");
    }

    function addBeneficiary(address _beneficiary, uint256 _tokenAmount) private {
        require(block.timestamp < cliffTime, "Invalid timing"); // It is not allowed to include new beneficiaries after cliff time
        require(_beneficiary != address(0), "The beneficiary's address cannot be 0");
        require(_tokenAmount > 0, "Amount has to be greater than 0");

        if (tokenAmounts[_beneficiary] == 0) {
            beneficiaries.push(_beneficiary);
        }

        lastReleaseDate[_beneficiary] = tgeTime;
        tokenAmounts[_beneficiary] += _tokenAmount;
    }

    function claimOwnTokens() public {
        _claimTokens(msg.sender);
    }

    function claimBeneficiaryTokens(address _beneficiary) public onlyOwner {
        _claimTokens(_beneficiary);
    }

    function _claimTokens(address _beneficiary) private {
        require(releasedAmount[_beneficiary] < tokenAmounts[_beneficiary], "User already released all available tokens");

        uint256 unreleased = releasableAmount(_beneficiary) - releasedAmount[_beneficiary];

        if (unreleased > 0) {
            released += unreleased;
            release(_beneficiary, unreleased);
            lastReleaseDate[_beneficiary] = block.timestamp;
        }
    }

    function userReleasableAmount(address _beneficiary) public view returns (uint256) {
        return releasableAmount(_beneficiary) - releasedAmount[_beneficiary];
    }

    function releasableAmount(address _account) private view returns (uint256) {
        if(block.timestamp > (start + duration)) return tokenAmounts[_account]; // Calling when vesting ended

        // Return 0 if time is before tgeTime
        if (block.timestamp < tgeTime) return 0; // TODO: check this part

        // ================== TGE CALCULATION ==================
        // Continue if time is after tge time
        uint256 tgePayment;
        if (tgePercentage > 0) { 
            // Calculate tge payment
            tgePayment = (tokenAmounts[_account] * tgePercentage) / BP;
        }
        // Time in before cliff time
        if(block.timestamp < cliffTime) return tgePayment;

        // ================== CLIFF CALCULATION ==================
        uint256 cliffPayment;
        if (cliffPercentage > 0) { 
            // Calculate cliff payment
            cliffPayment = (tokenAmounts[_account] * cliffPercentage) / BP;
        }

        // ================== VESTING PERIODS CALCULATION ==================
        uint256 periodsPassed = (block.timestamp - cliffTime) / period; // Periods passed after cliff end
        if(periodsPassed == 0) return tgePayment + cliffPayment;
       
        return tgePayment + cliffPayment + (tokenAmounts[_account] - (tgePayment + cliffPayment)) * periodsPassed / ((duration - (cliffTime - start))/ period);

    }

    function totalAmounts() public view returns (uint256 sum) {
        for (uint i = 0; i < beneficiaries.length; i++) {
            sum += tokenAmounts[beneficiaries[i]];
        }
    }

    function release(address _beneficiary, uint256 _amount) private {
        token.safeTransfer(_beneficiary, _amount);
        releasedAmount[_beneficiary] += _amount;
        emit Released(_beneficiary, _amount);
    }

    function beneficiariesLength() public view returns (uint256){
        return beneficiaries.length;
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