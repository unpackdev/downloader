// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/***************************************************************\
 .    . . . . . . .... .. ...................... . . . .  .   .+
   ..  .   . .. . ............................ ... ....  . .. .+
 .   .  .. .. ....... ..;@@@@@@@@@@@@@@@@@@@;........ ... .  . +
  .   .  .. ...........X 8@8X8X8X8X8X8X8X8X@ 8  ....... .. .. .+
.  .. . . ... ... .:..% 8 88@ 888888888888@%..8  .:...... . .  +
 .  . ... . ........:t:88888888@88888@8@888 ;  @......... .. ..+
.  . . . ........::.% 8 888@888888X888888  .   88:;:.:....... .+
.   . .. . .....:.:; 88888888@8888888@88      S.88:.:........ .+
 . . .. .......:.:;88 @8@8@888888@@88888.   .888 88;.:..:..... +
.  .. .......:..:; 8888888888888@88888X :  :Xt8 8 :S:.:........+
 .  .......:..:.;:8 8888888%8888888888 :. .888 8 88:;::::..... +
 . .. .......:::tS8@8888888@88%88888X ;. .@.S 8  %:  8:..:.....+
. .........:..::8888@S888S8888888888 ;. :88SS 8t8.    @::......+
 . . .....:.::.8@ 88 @88 @8 88@ 88 @::  8.8 8 8@     88:.:.....v
. . .......:.:;t8 :8 8 88.8 8:8.:8 t8..88 8 8 @ 8   88;::.:....+
.. .......:.:::;.%8 @ 8 @ .8:@.8 ;8;8t8:X@ 8:8X    88t::::.....+
. .. ......:..:::t88 8 8 8 t8 %88 88.@8 @ 888 X 8 XX;::::.::...+
..........:::::::;:X:8 :8 8 ;8.8.8 @ :88 8:@ @   8X;::::::.:...+
  . .......:.:::::; 8 8.:8 8 t8:8 8 8.;88 XX  8 88t;:::::......+
.. .......:.:.:::::; @:8.;8 8.t8 8 tt8.%8@. 8  88t;:;::::.:....+
 ... ....:.:.:.::;::; 8:8 ;8 8 t8 8:8 8.t8S. 888;;:;::::.:..:..+
.  ........::::::::;:;.t 8 ;8 8 ;88:;8.8 ;88 88S:::::::.:.:....+
 .. .. .....:.:.:::::;; 888X8S8 X@XSSS88 888X:t;;;::::::.:.....+
 .. ........:..:::::;::;%;:   .t. ;ttS:;t. .  :;;:;:::.::......+
 . . ......:.:..::::::;;;t;;:;;;;;;;;t;;;;;:: :;:;:::.:........+
/***************************************************************/

import "./LibDiamond.sol";
import "./LibRoyalty.sol";
import "./LibPayments.sol";
import "./ERC721AStorage.sol";
import "./ERC721AUpgradeable.sol";
import "./IDiamondLoupe.sol";
import "./IDiamondCut.sol";
import "./IERC173.sol";
import "./IERC165.sol";
import "./IERC2981.sol";
import "./IERC721.sol";
import "./console.sol";

contract DiamondInit is ERC721AUpgradeable {
    function init(bytes memory _calldata) external {
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
        ds.supportedInterfaces[type(IERC2981).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721).interfaceId] = true;

        // init ProjectConfig data
        (address[] memory owners, LibDiamond.ProjectConfig memory project, bool isUpgrade) = abi.decode(
            _calldata,
            (address[], LibDiamond.ProjectConfig, bool)
        );

        ds.project[LibDiamond.INNER_STRUCT].name = project.name;
        ERC721AStorage.layout()._name = project.name;
        ds.project[LibDiamond.INNER_STRUCT].symbol = project.symbol;
        ERC721AStorage.layout()._symbol = project.symbol;
        ds.project[LibDiamond.INNER_STRUCT].maxSupply = project.maxSupply;
        ds.project[LibDiamond.INNER_STRUCT].price = project.price;
        ds.project[LibDiamond.INNER_STRUCT].maxTotalMints = project.maxTotalMints;
        ds.project[LibDiamond.INNER_STRUCT].maxMintTxns = project.maxMintTxns;
        ds.project[LibDiamond.INNER_STRUCT].privateSaleTimestamp = project.privateSaleTimestamp;
        ds.project[LibDiamond.INNER_STRUCT].publicSaleTimestamp = project.publicSaleTimestamp;
        ds.project[LibDiamond.INNER_STRUCT].superAdmin = project.superAdmin;
        ds.project[LibDiamond.INNER_STRUCT].primaryDistRecipients = project.primaryDistRecipients;
        ds.project[LibDiamond.INNER_STRUCT].primaryDistShares = project.primaryDistShares;

        if (isUpgrade == false) {
            _initPaymentSplit(project.primaryDistRecipients, project.primaryDistShares);
        }

        ds.project[LibDiamond.INNER_STRUCT].royaltyReceiver = project.royaltyReceiver;
        LibRoyalty.layout()._defaultRoyaltyInfo.receiver = project.royaltyReceiver;
        ds.project[LibDiamond.INNER_STRUCT].royaltyFraction = project.royaltyFraction;
        LibRoyalty.layout()._defaultRoyaltyInfo.royaltyFraction = project.royaltyFraction;

        ds.project[LibDiamond.INNER_STRUCT].merkleroot = project.merkleroot;
        ds.project[LibDiamond.INNER_STRUCT]._baseURI = project._baseURI;
        ds.project[LibDiamond.INNER_STRUCT].closeDate = project.closeDate;
        ds.project[LibDiamond.INNER_STRUCT].minMint = project.minMint;

        if (isUpgrade == false) {
            ds.project[LibDiamond.INNER_STRUCT].startingIndex = project.startingIndex;
        }

        ds.project[LibDiamond.INNER_STRUCT].vrfCoordinator = project.vrfCoordinator;
        ds.project[LibDiamond.INNER_STRUCT].s_subscriptionId = project.s_subscriptionId;
        ds.project[LibDiamond.INNER_STRUCT].keyHash = project.keyHash;
        ds.project[LibDiamond.INNER_STRUCT].requestConfirmations = project.requestConfirmations;
        ds.project[LibDiamond.INNER_STRUCT].callbackGasLimit = project.callbackGasLimit;
        ds.project[LibDiamond.INNER_STRUCT].provenanceHash = project.provenanceHash;

        // update token owership state (if needed)
        if (isUpgrade == false) {
            transferPriorContractState(owners);
        }
    }

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    function _initPaymentSplit(address[] memory payees, uint256[] memory shares_) internal {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    event PayeeAdded(address account, uint256 shares);

    function _addPayee(address account, uint256 shares_) internal {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(LibPayments.layout()._shares[account] == 0, "PaymentSplitter: account already has shares");

        LibPayments.layout()._payees.push(account);
        LibPayments.layout()._shares[account] = shares_;
        LibPayments.layout()._totalShares = LibPayments.layout()._totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }

    function transferPriorContractState(address[] memory _owners) internal {
        if (_owners.length == 0) {
            return;
        }

        for (uint i = 0; i < _owners.length; i++) {
            _mint(_owners[i], 1);
        }
    }
}
