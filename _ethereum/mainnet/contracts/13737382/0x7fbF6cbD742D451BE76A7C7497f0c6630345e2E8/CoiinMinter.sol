pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./CoiinToken.sol";

contract CoiinMinter {
	using SafeMath for uint256;

	/// @notice More than this much time must pass between mint operations.
	uint256 public constant minMintTimeIntervalSec = 28 days;

	/// @notice Block timestamp of last mint operation
	uint256 public lastMintTimestampSec;

	/// @notice The length of the time window where a mint operation is allowed to execute, in seconds.
	uint256 public constant mintWindowLengthSec = 14 days;

	/// @notice The number of mint cycles since inception
	uint256 public epoch;

	/// @notice The address to mint new tokens
	address public mintAddress;

	/// @notice The COIIN token address
	address public coiinAddress;

	/// @notice The last mint amount
	uint256 public lastMintAmount;

	/// @notice The Multisig
	address public multiSig;

    //address public minter;
    mapping(address => bool) public isMinter;

	event Mint(uint256 epoch, uint256 amount);

	constructor(
		uint256 _firstIssuedTimeStamp,
		address _coiinAddress,
		address _mintAddress
	) public {
        require(_firstIssuedTimeStamp >= block.timestamp, "Wrong timestamp");
        require(_coiinAddress != address(0), "Wrong coiin address");
        require(_mintAddress != address(0), "Wrong mint address");
		lastMintTimestampSec = _firstIssuedTimeStamp;
		coiinAddress = _coiinAddress;
		mintAddress = _mintAddress;
		multiSig = msg.sender;
		lastMintAmount = 1000000 * 1e18;
	}

    modifier onlyMinter {
        require(isMinter[msg.sender], "Not Minter");
        _;
    }

	modifier onlyMultiSig {
		require(msg.sender == multiSig, "not owner");
		_;
	}

    function addMinter(address _minter) public onlyMultiSig {
        isMinter[_minter] = true;
    }

    function removeMinter(address _minter) public onlyMultiSig {
        isMinter[_minter] = false;
    }

	/*
	 * @notice Get last minted block timestamp
	 */
	function lastMinted() public view returns (uint256) {
		return lastMintTimestampSec;
	}

	/*
	 * @notice set mint address
	 * @notice must be multisig
	 * @param _address The new mint address where freshly minted COIIN will be sent
	 */
	function setMintAddress(address _address) public onlyMultiSig {
        require(_address != address(0), "Wrong mint address");
		mintAddress = _address;
	}

	/*
	 * @notice set multiSig address
	 * @notice must be multisig
	 * @param _address The new multiSig address
	 */
	function setMultiSig(address _multiSig) external onlyMultiSig {
        require(_multiSig != address(0), "Wrong multiSig address");
		multiSig = _multiSig;
	}

	/**
	 * @return If the latest block timestamp is within the mint time window it, returns true.
	 *         Otherwise, returns false.
	 */
	function inMintWindow() public view returns (bool) {
		return _inMintWindow();
	}

	function _inMintWindow() internal view returns (bool){
        uint256 timeElapsed = block.timestamp.sub(lastMintTimestampSec);
        uint256 window = timeElapsed.mod(minMintTimeIntervalSec);
        require(window < mintWindowLengthSec, "Not within mint window");
        return true;
	}

	/*
	 * @notice Time-based function that only allows callers to mint if a certain amount of time has passed
	 * @notice and only if the transaction was created in the valid mint window
	 */
	function mint(uint256 _amount) public onlyMinter {
		// ensure minting at correct time
		_inMintWindow();

		CoiinToken coiin = CoiinToken(coiinAddress);

		// This comparison also ensures there is no reentrancy.
		require(lastMintTimestampSec.add(minMintTimeIntervalSec) < block.timestamp, "Min mint interval not elapsed");

		// _amount cannot be less than minMintMonthly
		require(_amount >= coiin.minMintMonthly(), "amount cannot be less than min mint amount");

		// _amount cannot exceed maxMintMonthly
		require(_amount <= coiin.maxMintMonthly(), "amount cannot be more than max mint amount");

		// _amount cannot be more than 25% of the lastMintAmount
        // amount > lastMintAmount + 25%
        // changed to:
        // amount < lastMintAmount + 25%
		require(
			_amount < lastMintAmount.add(lastMintAmount.mul(25).div(100)),
			"Amount must be less than 125% lastMintAmount"
		);

		// _amount cannot be less than 25% of the lastMintAmount
        // amount < lastMintAmount - 25%
        // changed to:
        // amount > lastMintAmount - 25%
		require(
			_amount > lastMintAmount.sub(lastMintAmount.mul(25).div(100)),
			"Amount must be more than 75% of lastMintAmount"
		);

		lastMintAmount = _amount;

		// snap the mint time to the start of this window.

        uint256 timeElapsed = block.timestamp.sub(lastMintTimestampSec);
        uint256 windowOverrun = timeElapsed.mod(minMintTimeIntervalSec);
        lastMintTimestampSec = block.timestamp.sub(windowOverrun);

		epoch = epoch.add(1);

		require(coiin.mint(mintAddress, _amount), "error occurred while minting");
		emit Mint(epoch, _amount);
	}
}
