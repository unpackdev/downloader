// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**************************************************************\
 * Initialiser contract authored by Bling Artist Lab
 * Version 0.4.0
 * 
 * This initialiser contract has been written specifically for
 * ERC721A-DIAMOND-TEMPLATE by Bling Artist Lab
/**************************************************************/

import "./GlobalState.sol";
import "./AllowlistFacet.sol";
import "./TokenFacet.sol";
import "./ERC165Facet.sol";
import "./ERC721AStorage.sol";
import "./ERC721A__InitializableStorage.sol";
import "./PaymentSplitterFacet.sol";
import "./RoyaltiesConfigFacet.sol";

contract DiamondInit {

    function initAll() public {
        initAdminPrivilegesFacet();
        initTokenFacet();
        initERC165Facet();
        initPaymentSplitterFacet();
        initRoyaltiesConfigFacet();
    }

    // AdminPrivilegesFacet //

    function initAdminPrivilegesFacet() public {
        // List of admins must be placed inside this function,
        // as arrays cannot be constant and
        // therefore will not be accessible by the
        // delegatecall from the diamond contract.
        address[] memory admins = new address[](1);
        admins[0] = 0x91D162E6c2C8E646D100781F59FAb7DDa2865F64; //tbd

        for (uint256 i; i < admins.length; i++) {
            GlobalState.getState().admins[admins[i]] = true;
        }
    }

    // TokenFacet //

    string private constant name = "MomentsAsia365";
    string private constant symbol = "MA365";
    string private constant preRevealURI = "ipfs://bafybeifucwd44wlg7ewt3pjwbtmytpsrshans5agistj6ikgbr5mzxj4dy/prereveal.png";
    string private constant baseURI = "https://bafybeific3erby3nlhhc7ngrarpvrps7lomgkqfwnlmbhshir2qisjox6y.ipfs.nftstorage.link/";
    uint256 private constant startTokenId = 0;
    uint256 private constant startTimeStamp = 1702990800;
    uint256 private constant endTimeStamp = 1703595600;
    uint256 private constant unitDuration = 86400;

    function initTokenFacet() public {
        // Variables in array format must be placed inside this
        // function, as arrays cannot be constant and therefore
        // will not be accessible by the delegatecall from the
        // diamond contract.

        uint256[] memory price = new uint256[](2);
        price[0] = 0.03 ether; // allowlist
        price[1] = 0.0365 ether; // public

        uint256[] memory breakPoints = new uint256[](3);
        breakPoints[0] = 0;
        breakPoints[1] = 11;
        breakPoints[2] = 366;

        string[] memory city = new string[](18);
        city[0] = "Seoul";
        city[1] = "Incheon";
        city[2] = "Suwon";
        city[3] = "Boseong";
        city[4] = "Gyeongju";
        city[5] = "Busan";
        city[6] = "Ulsan";
        city[7] = "Cheonan";
        city[8] = "Suncheon";
        city[9] = "Korea";
        city[10] = "Osaka";
        city[11] = "Kyoto";
        city[12] = "Koyasan";
        city[13] = "Tokyo";
        city[14] = "Enoshima";
        city[15] = "Japan";
        city[16] = "Hong Kong";
        city[17] = "Macau";

        uint256[] memory day = new uint256[](18);
        day[0] = 61;
        day[1] = 64;
        day[2] = 66;
        day[3] = 67;
        day[4] = 68;
        day[5] = 120;
        day[6] = 121;
        day[7] = 126;
        day[8] = 127;
        day[9] = 135;
        day[10] = 187;
        day[11] = 229;
        day[12] = 241;
        day[13] = 294;
        day[14] = 297;
        day[15] = 302;
        day[16] = 354;
        day[17] = 365;

        uint256 globalRandom = uint256(keccak256(abi.encodePacked(
            block.number, block.timestamp, block.prevrandao, block.gaslimit, msg.sender, gasleft(), msg.data, tx.gasprice
        )));

        TokenFacetLib.state storage s1 = TokenFacetLib.getState();

        s1.startTimeStamp = startTimeStamp;
        s1.endTimeStamp = endTimeStamp;
        s1.revealTimeStamp = endTimeStamp;
        s1.globalRandom = globalRandom;
        s1.unitDuration = unitDuration;
        s1.preRevealURI = preRevealURI;
        s1.baseURI = baseURI;
        
        s1.breakPoints = breakPoints;
        s1.price = price;
        s1.day = day;
        s1.city = city;

        ERC721AStorage.Layout storage s2 = ERC721AStorage.layout();

        s2._name = name;
        s2._symbol = symbol;
        s2._currentIndex = startTokenId;

        ERC721A__InitializableStorage.layout()._initialized = true;

        TokenFacetLib.initImage();
    }

    // ERC165Facet //

    bytes4 private constant ID_IERC165 = 0x01ffc9a7;
    bytes4 private constant ID_IERC173 = 0x7f5828d0;
    bytes4 private constant ID_IERC2981 = 0x2a55205a;
    bytes4 private constant ID_IERC721 = 0x80ac58cd;
    bytes4 private constant ID_IERC721METADATA = 0x5b5e139f;
    bytes4 private constant ID_IDIAMONDLOUPE = 0x48e2b093;
    bytes4 private constant ID_IDIAMONDCUT = 0x1f931c1c;

    function initERC165Facet() public {
        ERC165Lib.state storage s = ERC165Lib.getState();

        s.supportedInterfaces[ID_IERC165] = true;
        s.supportedInterfaces[ID_IERC173] = true;
        s.supportedInterfaces[ID_IERC2981] = true;
        s.supportedInterfaces[ID_IERC721] = true;
        s.supportedInterfaces[ID_IERC721METADATA] = true;

        s.supportedInterfaces[ID_IDIAMONDLOUPE] = true;
        s.supportedInterfaces[ID_IDIAMONDCUT] = true;
    }

    // PaymentSplitterFacet //

    function initPaymentSplitterFacet() public {
        // Lists of payees and shares must be placed inside this
        // function, as arrays cannot be constant and therefore
        // will not be accessible by the delegatecall from the
        // diamond contract.
        address[] memory payees = new address[](1);
        payees[0] = 0x91D162E6c2C8E646D100781F59FAb7DDa2865F64;

        uint256[] memory shares = new uint256[](1);
        shares[0] = 1;

        require(payees.length == shares.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            PaymentSplitterLib._addPayee(payees[i], shares[i]);
        }
    }

    // RoyaltiesConfigFacet //

    address payable private constant royaltyRecipient = payable(0x70d6eB2B3b9a2a7D6D67c3f24c246BFFC05b48Ca); //tbd
    uint256 private constant royaltyBps = 1000; //tbd

    function initRoyaltiesConfigFacet() public {
        RoyaltiesConfigLib.state storage s = RoyaltiesConfigLib.getState();

        s.royaltyRecipient = royaltyRecipient;
        s.royaltyBps = royaltyBps;
    }

}