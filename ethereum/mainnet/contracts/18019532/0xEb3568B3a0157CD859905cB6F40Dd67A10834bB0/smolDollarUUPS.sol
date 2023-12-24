// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.17;

//    V.1
//   ____________________________________
//   |::::::/-/-/-/-/-/-/-/-/-/-/-::::::|
//   |:(1)*······SMOL.DOLLAR·······*(1):|
//   |:''·········/¯¯¯¯¯¯¯\··'''''''·'':|
//   |':{G}·······| ʕ•ᴥ•ʔ |···········:'|
//   |:'···''''''·| { . } |····O.N.E.·':|
//   |:(1)········\_______/·········(1):|
//   |//-------ONE.SMOL.DOLLAR--------//|
//   ------------------------------------
//

import "./ERC2981Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";

import "./ERC721AUpgradeable.sol";
import "./ERC721AQueryableUpgradeable.sol";
import "./ERC721A__Initializable.sol";
import "./OperatorFilterer.sol";

import "./seedGenerator.sol";
import "./operatorWhitelist.sol";

contract smolDollar is
    ERC721AUpgradeable,
    ERC721AQueryableUpgradeable,
    ERC2981Upgradeable,
    OwnableUpgradeable,
    OperatorFilterer,
    seedGenerator,
    operatorWhitelist,
    UUPSUpgradeable
{
    address public Minting;
    address public Seigniorage;
    address public Bonds;
    address public SVGRendering;
    bool public SeigniorageOn;
    bool public BurningBondsOn;
    mapping(uint256 => uint256) TokenIdToSeed;

    function initialize() public initializerERC721A initializer {
        __ERC721A_init("Smol Dollar", "(o_o)");
        __Ownable_init();
        __ERC2981_init();
        __UUPSUpgradeable_init();

        _registerForOperatorFiltering();

        // Set royalty receiver to the contract creator,
        // at 9% (default denominator is 10000).
        // this sets the Default Royalty in ERC2981
        _setDefaultRoyalty(msg.sender, 900);
        SeigniorageOn = false;
        BurningBondsOn = false;
    }

    /// UUPS
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    // overwrite start token
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// Mint Function
    function mint(uint256 quantity, address minter) external {
        require(msg.sender == Minting, "NOT_AUTORIZED");
        uint256 nextID = _nextTokenId();
        for (uint256 max = 0; max < quantity; max++) {
            TokenIdToSeed[nextID + max] = createTokenChar(nextID + max);
        }
        // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
        _mint(minter, quantity);
    }

    // ERC2981 ROYALTY + Interfaces

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721AUpgradeable, IERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    // closedsea + ERC2981 ROYALTY

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // change Addresses

    function setRender(address render) public onlyOwner {
        SVGRendering = render;
    }

    function setSeigniorage(address seigniorage) public onlyOwner {
        Seigniorage = seigniorage;
    }

    function setBonds(address bonds) public onlyOwner {
        Bonds = bonds;
    }

    function setMinting(address minting) public onlyOwner {
        Minting = minting;
    }

    // turn on Seigiorage / Bonds

    function setBoolSeigniorage(bool onOf) public onlyOwner {
        SeigniorageOn = onOf;
    }

    function setBoolBonds(bool onOf) public onlyOwner {
        BurningBondsOn = onOf;
    }

    // overwriting transfer

    function setApprovalForAll(
        address operator,
        bool approved
    )
        public
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    /// both safeTransfer Calls end up here :(
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperator(from)
        seigniorageCall(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    /// general problem with the openseafilter - safeTransferFrom calls transfer from so the modifier is at least two times enforced - gas bad
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    modifier seigniorageCall(address from) virtual {
        bool notUsesOperator = (msg.sender != from);
        if (
            (SeigniorageOn &&
                notUsesOperator &&
                checkOperatorWhitelist(msg.sender))
        ) {
            (bool suc, ) = address(Seigniorage).call(
                abi.encodeWithSignature("addPoint(address)", from)
            );
            require(suc, "Call_failed");
        }
        _;
    }

    /// add Whitelist Operators
    function addWhitelistSlot(uint8 slot, address operator) public onlyOwner {
        _addSlot(slot, operator);
    }

    // burningBonds
    // If approvalCheck (second argument is true, the caller must own tokenId or be an approved operator.
    // DANGER WE SET IT HERE TO FALSE BECAUSE THIS IS CALLED BY A DIFFRENT CONTRACT
    // DANGER THE BONDS CONTRACT HAS TO CHECK THAT THE TOKEN IS OWNED BY THE ADDESS WHICH BURNS IT
    function burn(uint256 tokenId) external {
        require(msg.sender == Bonds);
        require(BurningBondsOn == true);
        _burn(uint256(tokenId), bool(false));
    }

    /// renderfunction

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        virtual
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        returns (string memory)
    {
        (bool suc, bytes memory returnData) = address(SVGRendering).staticcall(
            abi.encodeWithSignature("render(uint256)", TokenIdToSeed[tokenId])
        );
        require(suc, "Call failed");
        return abi.decode(returnData, (string));
    }

    /// opensea : 0x1E0049783F008A0085193E00003D00cd54003c71
    /// blur : 0x2f18f339620a63e43f0839eeb18d7de1e1be4dfb
    ///closedSea
    function _isPriorityOperator(
        address operator
    ) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}
