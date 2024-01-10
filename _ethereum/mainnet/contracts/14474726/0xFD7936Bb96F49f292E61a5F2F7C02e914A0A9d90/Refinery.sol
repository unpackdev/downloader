// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Pausable.sol";
import "./IERC1155TokenReceiver.sol";
import "./IRefinery.sol";
import "./IImperialGuild.sol";
import "./IEON.sol";
import "./IRAW.sol";

contract Refinery is IRefinery, IERC1155TokenReceiver, Pausable {
    struct UserInfo {
        uint256 amount; // how many raw materials has this user added
        uint256 refineEndBlock; // block your refining will be refined
        uint256 lastClaimBlock; // block of your last claim
    }

    /* ERC1155 Refineries what they take in and what they output at what rate

    struct RefineryInfo {
        uint8 inputType; // raw input typeID
        uint8 outputType; // refined resourse typeID
        uint8 burnRate; // rate of input burn to refined per block
        uint8 refineRate; // rate cut of raw to refined
    }
*/
    uint256 public constant multiplier = 10**18;

    // keys for each refinery in operation
    RefineryInfo[] public refineryInfo;

    address public auth;

    // mapping(uint256 => Refinery) public RefineryInfo;
    //maps refineries to users
    mapping(uint256 => mapping(address => UserInfo)) public userRefines;

    // address => allowedToCallFunctions
    mapping(address => bool) private admins;

    // Deposits to specified refinery
    event DepositRaw(address indexed user, uint256 indexed rid, uint256 amount);

    // Withdraws of unrefined
    event WithdrawRaw(
        address indexed user,
        uint256 indexed rid,
        uint256 amount
    );
    event EmergencyWithdrawRaw(
        address indexed user,
        uint256 indexed rid,
        uint256 amount
    );

    IRAW public raw;

    IEON public eon;

    // emergency withdraw to allow removing unrefined without no care for the refined amount
    bool public emergencyActivated;

    constructor() {
        _pause();
        auth = msg.sender;
        admins[msg.sender] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == auth);
        _;
    }

    modifier requireContractsSet() {
        require(
            address(raw) != address(0) && address(eon) != address(0),
            "Contracts not set"
        );
        _;
    }

    modifier noCheaters() {
        uint256 size = 0;
        address acc = msg.sender;
        assembly {
            size := extcodesize(acc)
        }

        require(
            admins[msg.sender] || (msg.sender == tx.origin && size == 0),
            "you're trying to cheat!"
        );
        _;
    }

    function setContracts(address _raw, address _eon) external onlyOwner {
        raw = IRAW(_raw);
        eon = IEON(_eon);
    }

    /**
   * store information on the types of refineries
   * available to this refinery
   @param _inputType the RAW ERC1155 typeId resource
   @param _outputType refined output typeId
   * ATTENTION reserve outputType 0 for EON ERC20
   * non 0 outputType points to RAW ERC1155
   @param _burnRate inputType burn rate multiplied by block time dif
   @param _refineRate outputType rate
   */
    function addRefinery(
        uint8 _inputType,
        uint8 _outputType,
        uint8 _burnRate,
        uint8 _refineRate
    ) external onlyOwner {
        refineryInfo.push(
            RefineryInfo({
                inputType: _inputType,
                outputType: _outputType,
                burnRate: _burnRate,
                refineRate: _refineRate
            })
        );
    }

    // update a refinery if needed
    function updateRefineryInfo(
        uint8 _rid,
        uint8 _inputType,
        uint8 _outputType,
        uint8 _burnRate,
        uint8 _refineRate
    ) external onlyOwner {
        refineryInfo[_rid].inputType = _inputType;
        refineryInfo[_rid].outputType = _outputType;
        refineryInfo[_rid].burnRate = _burnRate;
        refineryInfo[_rid].refineRate = _refineRate;
    }

    function getRefineryInfo(uint256 _rid)
        external
        view
        returns (RefineryInfo memory)
    {
        return refineryInfo[_rid];
    }

    // how long has the raw resource been refining for
    function getTimeDif(uint256 _current, uint256 _lastClaim)
        internal
        pure
        returns (uint256)
    {
        return (_current - _lastClaim);
    }

    // how much of the raw resource has been refined thus far
    // and what is the expected output of the refined
    function pendingRefine(uint256 _rid, address _user)
        external
        view
        returns (uint256 refining, uint256 refined)
    {
        RefineryInfo memory refinery = refineryInfo[_rid];
        UserInfo storage user = userRefines[_rid][_user];

        if (block.number < user.refineEndBlock) {
            uint256 timeDif = getTimeDif(block.number, user.lastClaimBlock);
            uint256 burnAmt = refinery.burnRate * timeDif;
            uint256 remaining = user.amount - burnAmt;
            uint256 refineRateCut = (refinery.refineRate * burnAmt) / 100;
            uint256 userRefined = (burnAmt - refineRateCut);
            return (remaining, userRefined);
        } else if (block.number > user.refineEndBlock) {
            uint256 burnAmt = user.amount;
            uint256 refineRateCut = (refinery.refineRate * burnAmt) / 100;
            uint256 userRefined = (burnAmt - refineRateCut);
            return (0, userRefined);
        }
    }

    // updating a refinery to check amounts still refining and
    // the output of the refined, this function is called any time
    // a deposit or claim is made by the user
    function updateRefined(
        uint256 _rid,
        uint256 _amount,
        address refiner
    ) private returns (uint256 burn, uint256 refined) {
        RefineryInfo memory refinery = refineryInfo[_rid];
        UserInfo storage user = userRefines[_rid][refiner];
        if (block.number < user.refineEndBlock) {
            uint256 timeDif = getTimeDif(block.number, user.lastClaimBlock);
            uint256 burnAmt = refinery.burnRate * timeDif;
            uint256 refineRateCut = (refinery.refineRate * burnAmt) / 100;
            uint256 refinedAmt = (burnAmt - refineRateCut);
            uint256 updatedRefining = (user.amount - burnAmt) + _amount;
            user.lastClaimBlock = block.number;
            user.refineEndBlock =
                (updatedRefining / refinery.burnRate) +
                block.number;
            user.amount = updatedRefining;
            return (burnAmt, refinedAmt);
        } else if (block.number > user.refineEndBlock && user.amount != 0) {
            uint256 burnAmt = user.amount;
            uint256 refineRateCut = ((refinery.refineRate * burnAmt) / 100);
            uint256 refinedAmt = (burnAmt - refineRateCut);
            user.lastClaimBlock = block.number;
            user.amount = _amount;
            user.refineEndBlock = (_amount / refinery.burnRate) + block.number;
            return (burnAmt, refinedAmt);
        }
    }

    /* Deposit ERC1155s to the refinery
     * Claims any already refined amounts for user
     * within this refinery id (_rid)
     * token id needs to be the raw.typeId of the input
     */
    function depositRaw(
        uint256 _rid,
        uint256 _tokenId,
        uint256 _amount
    ) external whenNotPaused noCheaters {
        require(tx.origin == msg.sender, "Only EOA");
        RefineryInfo memory refinery = refineryInfo[_rid];
        UserInfo storage user = userRefines[_rid][msg.sender];
        uint256 typeId = refinery.inputType;
        uint256 outputId = refinery.outputType;
        //claim
        if (user.amount > 0) {
            (uint256 burnAmt, uint256 refinedAmt) = updateRefined(
                _rid,
                _amount,
                msg.sender
            );
            raw.burn(typeId, burnAmt, address(this));
            if ((outputId == 0)) {
                uint256 mint = refinedAmt * multiplier;
                eon.mint(msg.sender, mint);
            } else {
                raw.mint(outputId, refinedAmt, msg.sender);
            }
        }
        require(_tokenId == refinery.inputType);
        //transfer the raw ERC1155s to this contract
        raw.safeTransferFrom(
            address(msg.sender),
            address(this),
            (refinery.inputType),
            _amount,
            ""
        );

        //Initiate Deposit
        if (user.amount == 0) {
            // if the first depoist
            user.refineEndBlock = (_amount / refinery.burnRate) + block.number;
            user.lastClaimBlock = block.number;
            user.amount += _amount;
        }
        emit DepositRaw(msg.sender, _rid, _amount);
    }

    /* withdraw UNREFINED erc1155s
     * will withdraw the full unrefined input of user
     * will also claim all refined
     */
    function withdrawRaw(uint256 _rid) external whenNotPaused noCheaters {
        require(tx.origin == msg.sender, "Only EOA");
        RefineryInfo memory refinery = refineryInfo[_rid];
        UserInfo storage user = userRefines[_rid][msg.sender];
        uint256 typeId = refinery.inputType;
        uint256 outputId = refinery.outputType;
        uint8 eonType = 0;
        if (user.amount > 0) {
            (uint256 burnAmt, uint256 refinedAmt) = updateRefined(
                _rid,
                0,
                msg.sender
            );
            uint256 unrefined = (user.amount - burnAmt);
            user.amount = 0;
            raw.safeTransferFrom(
                address(this),
                msg.sender,
                typeId,
                unrefined,
                ""
            );
            if (burnAmt > 0 && refinedAmt > 0) {
                raw.burn(typeId, burnAmt, address(this));
                if ((outputId == eonType)) {
                    eon.mint(msg.sender, refinedAmt);
                } else {
                    raw.mint(outputId, refinedAmt, msg.sender);
                }
            }
            emit WithdrawRaw(msg.sender, _rid, unrefined);
        }
    }

    // Withdraw RAW resources without caring about the refined amount. EMERGENCY ONLY
    // Add a rescue pause enabled modifier
    function emergencyWithdraw(uint256 _rid) external {
        require(emergencyActivated, "THIS IS NOT AN EMERGENCY SITUATION");
        RefineryInfo memory refinery = refineryInfo[_rid];
        UserInfo storage user = userRefines[_rid][msg.sender];
        uint256 typeId = refinery.inputType;
        uint256 unrefined = user.amount;

        raw.safeTransferFrom(address(this), msg.sender, typeId, unrefined, "");
        // user.amount.safeTransfer(address(msg.sender), user.amount);
        user.amount = 0;
        user.lastClaimBlock = block.number;
    }

    /** admin
     * enables owner to active "emergency mode"
     * thus allow users to withdraw unrefined resouces without the refined gained
     */

    function activateEmergency(bool _enabled) external onlyOwner {
        emergencyActivated = _enabled;
    }

    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external requireContractsSet onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /**
     * enables an address to mint / burn
     * @param addr the address to enable
     */
    function addAdmin(address addr) external onlyOwner {
        admins[addr] = true;
    }

    /**
     * disables an address from minting / burning
     * @param addr the address to disbale
     */
    function removeAdmin(address addr) external onlyOwner {
        admins[addr] = false;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC1155TokenReceiver.onERC1155Received.selector;
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }
}
