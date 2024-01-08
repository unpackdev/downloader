//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "./console.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";


contract Vesting is Ownable {

    using SafeMath for uint256;

    IERC20 public erc20;

    uint256 public periodInDays;

    uint256 public totalDeposit;

    bytes4 private constant _INTERFACE_ID_ERC721 = type(IERC721).interfaceId;

    struct Deposit {
        uint256 start;
        uint256 amountPerPeriod;
        uint256 alreadyWithdrawn;
        uint16 numberOfPayments;
    }

    event DepositEvent(
        address indexed erc721,
        uint256 indexed tokenId,
        uint256 start,
        uint256 amountPerPeriod,
        uint16 numberOfPayments
    );

    event WithdrawEvent(
        address indexed erc721,
        uint256 indexed tokenId,
        uint256 amount,
        address owner
    );

    mapping(address => mapping(uint256 => Deposit)) public deposits;
    mapping(address => bool) public erc721sIntegrated;
    address[] public erc721Array;
    mapping(address => uint256[]) public erc721sIdMapping;


    constructor(address _erc20, uint256 _periodInDays) {
        require(_periodInDays > 0 , "periodInDays must be bigger than 0");
        erc20 = IERC20(_erc20);
        periodInDays = _periodInDays;
    }

    /**
     * @dev Returns the Start timestamp or the vesting, amount of Erc20 tokens will be vested on every period,
     * amount of Erc20 tokens already withdrawn, total number of payment cycles
     *
     */
    function balanceOf(address erc721, uint256 tokenId) public view returns (uint256, uint256, uint256, uint16) {
        Deposit storage deposit = deposits[erc721][tokenId];
        return (deposit.start, deposit.amountPerPeriod, deposit.alreadyWithdrawn, deposit.numberOfPayments);
    }

    /** @dev Creates Deposit for an ERC721 token and increases totalDeposit as start current blocktime
      *
      * Emits a {DepositEvent} event
      *
      * Requirements:
      *
      * - No previous deposit for `erc721` and `tokenId`
      * - ERC20 balance of this token > `totalDeposit` + (`amountPerPeriod` * `numberOfPayments`)
      *
      */
    function deposit(address erc721, uint256 tokenId, uint256 amountPerPeriod, uint16 numberOfPayments) external onlyOwner {

        require(erc20.balanceOf(address(this)) >= totalDeposit.add(amountPerPeriod.mul(numberOfPayments)), "Insufficient funds for a new deposit.");
        require(IERC721(erc721).supportsInterface(_INTERFACE_ID_ERC721), "Address provided for erc721 contract is not implementing IERC721.");

        _deposit(erc721, tokenId, amountPerPeriod, numberOfPayments, 0);
    }

    /** @dev Creates Deposit for an ERC721 token and increases totalDeposit
     *
     * Emits a {DepositEvent} event
     *
     * Requirements:
     *
     * - No previous deposit for `erc721` and `tokenId`
     * - ERC20 balance of this token > `totalDeposit` + (`amountPerPeriod` * `numberOfPayments`)
     *
     */
    function deposit(address erc721, uint256 tokenId, uint256 amountPerPeriod, uint16 numberOfPayments,  uint256 start) external onlyOwner {

        require(erc20.balanceOf(address(this)) >= totalDeposit.add(amountPerPeriod.mul(numberOfPayments)), "Insufficient funds for a new deposit.");
        require(IERC721(erc721).supportsInterface(_INTERFACE_ID_ERC721), "Address provided for erc721 contract is not implementing IERC721.");

        _deposit(erc721, tokenId, amountPerPeriod, numberOfPayments, start);
    }

    /** @dev Creates Deposit for all ERC721 tokens in list and increases totalDeposit with start as current blocktime
     *
     * Emits a {DepositEvent} event
     * Gas limit can be reached around 130 deposits
     * Requirements:
     *
     * For every token Contract address and token Id, function will do
     * - No previous deposit for `erc721` and `tokenId`
     * - ERC20 balance of this token > `totalDeposit` + (`amountPerPeriod` * `numberOfPayments`)
     *
     */
    function depositBatch(address[] memory erc721List, uint256[] memory tokenIdList, uint256 amountPerPeriod, uint16 numberOfPayments) external onlyOwner {
        require(erc721List.length == tokenIdList.length, "Length of erc721List and tokenIdList must be same.");
        require(erc20.balanceOf(address(this)) >= totalDeposit.add(tokenIdList.length.mul(amountPerPeriod.mul(numberOfPayments))), "Insufficient funds for a new deposit.");

        for (uint i = 0; i < erc721List.length; i++) {
            require(IERC721(erc721List[i]).supportsInterface(_INTERFACE_ID_ERC721), "Address provided for erc721 contract is not implementing IERC721.");
        }

        for (uint i = 0; i < erc721List.length; i++) {
            _deposit(erc721List[i], tokenIdList[i], amountPerPeriod, numberOfPayments, 0);
        }
    }

    /** @dev Creates Deposit for all ERC721 tokens in list and increases totalDeposit
     *
     * Emits a {DepositEvent} event
     * Gas limit can be reached around 130 deposits
     * Requirements:
     *
     * For every token Contract address and token Id, function will do
     * - No previous deposit for `erc721` and `tokenId`
     * - ERC20 balance of this token > `totalDeposit` + (`amountPerPeriod` * `numberOfPayments`)
     *
     */
    function depositBatch(address[] memory erc721List, uint256[] memory tokenIdList, uint256 amountPerPeriod, uint16 numberOfPayments,  uint256 start) external onlyOwner {
        require(erc721List.length == tokenIdList.length, "Length of erc721List and tokenIdList must be same.");
        require(erc20.balanceOf(address(this)) >= totalDeposit.add(tokenIdList.length.mul(amountPerPeriod.mul(numberOfPayments))), "Insufficient funds for a new deposit.");

        for (uint i = 0; i < erc721List.length; i++) {
            require(IERC721(erc721List[i]).supportsInterface(_INTERFACE_ID_ERC721), "Address provided for erc721 contract is not implementing IERC721.");
        }

        for (uint i = 0; i < erc721List.length; i++) {
            _deposit(erc721List[i], tokenIdList[i], amountPerPeriod, numberOfPayments, start);
        }
    }


    function _deposit(address erc721, uint256 tokenId, uint256 amountPerPeriod, uint16 numberOfPayments, uint256 start) internal {
        require(deposits[erc721][tokenId].start == 0, "Already Deposited for the token.");
        if (erc721sIntegrated[erc721] == false) {
            erc721sIntegrated[erc721] = true;
            erc721Array.push(erc721);
        }
        erc721sIdMapping[erc721].push(tokenId);

        if (start == 0 ) {
            start = block.timestamp;
        }

        totalDeposit = totalDeposit.add(amountPerPeriod.mul(numberOfPayments));
        Deposit storage deposit = deposits[erc721][tokenId];
        deposit.start = start;
        deposit.amountPerPeriod = amountPerPeriod;
        deposit.numberOfPayments = numberOfPayments;
        emit DepositEvent(erc721, tokenId, deposit.start, deposit.amountPerPeriod, deposit.numberOfPayments);
    }

    /** @dev Withdraws vested amount for an ERC721 token and decrease totalDeposit
      * for every item on the lists
      * Emits a {WithdrawEvent} event for every successful withdraw.
      *
      * Stops loop if there is not enough gas left for the next
      *
      */
    function withdrawBatch(address[] memory erc721List, uint256[] memory tokenIdList) external {
        require(erc721List.length == tokenIdList.length, "Length of erc721List and tokenIdList must be same.");
        uint256 startGas = gasleft();
        uint256 maxGasInStep = 0;
        for (uint i = 0; i < erc721List.length; i++) {
            _withdraw(erc721List[i], tokenIdList[i]);
            uint256 gasUsedInStep = startGas - gasleft();
            if (gasUsedInStep > maxGasInStep) {
                maxGasInStep = gasUsedInStep;
            }
            startGas = gasleft();
            if (maxGasInStep * 2 > gasleft()) {
                break;
            }
        }
    }

    /** @dev Withdraws vested amount for an ERC721 token and decrease totalDeposit
     *
     * Emits a {WithdrawEvent} event.
     *
     */
    function withdraw(address erc721, uint256 tokenId) external {
        _withdraw(erc721, tokenId);
    }


    function _withdraw(address erc721, uint256 tokenId) internal {
        Deposit storage deposit = deposits[erc721][tokenId];
        uint totalDaysFromStart = (block.timestamp - deposit.start) / 60 / 60 / 24;
        uint totalPeriodsPast = totalDaysFromStart / periodInDays;
        if (totalPeriodsPast > deposit.numberOfPayments) {
            totalPeriodsPast = deposit.numberOfPayments;
        }
        uint amountToWithdraw = totalPeriodsPast * deposit.amountPerPeriod - deposit.alreadyWithdrawn;
        if (amountToWithdraw > 0) {
            deposit.alreadyWithdrawn += amountToWithdraw;
            address tokenOwner = IERC721(erc721).ownerOf(tokenId);
            totalDeposit -= amountToWithdraw;
            erc20.transfer(tokenOwner, amountToWithdraw);
            emit WithdrawEvent(erc721, tokenId, amountToWithdraw, tokenOwner);
        }
    }

    /** @dev Withdraws vested amount for an ERC721 token and decrease totalDeposit
      * for every token of erc721 until out of gas
      * Emits a {WithdrawEvent} event for every successful withdraw.
      *
      * Stops loop if there is not enough gas left for the next
      *
      */
    function withdrawForAllTokensOf(address erc721) external {

        uint256 startGas = gasleft();
        uint256 maxGasInStep = 0;
        for (uint256 i = 0; i < erc721sIdMapping[erc721].length; i++) {
            _withdraw(erc721, erc721sIdMapping[erc721][i]);
            uint256 gasUsedInStep = startGas - gasleft();
            if (gasUsedInStep > maxGasInStep) {
                maxGasInStep = gasUsedInStep;
            }
            startGas = gasleft();
            if (maxGasInStep * 2 > gasleft()) {
                break;
            }
        }

    }

    /** @dev Withdraws vested amount for all and decrease totalDeposit
    * for every token until out of gas
    * Emits a {WithdrawEvent} event for every successful withdraw.
    *
    * Stops loop if there is not enough gas left for the next
    *
    */
    function withdrawAll() external {

        uint256 startGas = gasleft();
        uint256 maxGasInStep = 0;
        for (uint256 i = 0; i < erc721Array.length; i++) {

            for (uint256 j = 0; j < erc721sIdMapping[erc721Array[i]].length; j++) {
                _withdraw(erc721Array[i], erc721sIdMapping[erc721Array[i]][j]);
                uint256 gasUsedInStep = startGas - gasleft();
                if (gasUsedInStep > maxGasInStep) {
                    maxGasInStep = gasUsedInStep;
                }
                startGas = gasleft();
                if (maxGasInStep * 2 > gasleft()) {
                    break;
                }
            }
        }

    }

    function erc721ArraySize() public view returns (uint256) {
        return erc721Array.length;
    }

    function erc721TokenSize(address erc721) public view returns (uint256) {
        return erc721sIdMapping[erc721].length;
    }

    function getTokenId(address erc721, uint256 index) public view returns (uint256) {
        return erc721sIdMapping[erc721][index];
    }
}
