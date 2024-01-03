// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import "./IERC721Receiver.sol";
import "./ERC20.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";

import "./IXPGFKRecipient.sol";

contract ParticleBridge is IERC721Receiver {
    using Counters for Counters.Counter;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private _retval = 0x150b7a02;

    // Equals to 27c231b6 => bytes4(keccak256("onXPGFKReceived(address,address,uint256,bytes)")
    bytes4 private constant _XPGFK_RECEIVED = 0x27c231b6;

    address private _owner;
    address private _pgfk;
    address private _pgfkOwner;

    mapping(uint256 => address) private _xpgfkGens;
    mapping(address => uint256) private _xpgfkRatios;
    mapping(uint256 => address) private _xpgfkGenOwners;

    Counters.Counter private _tokenId;

    ERC20 public ERC20Interface;
    ERC721Burnable public ERC721BurnableInterface;

    event Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes data,
        uint256 gas
    );

    constructor() public {
        _owner = msg.sender;
    }

    /**
     * Private helper functions
     */

    // _xpgfkOwner must permission address(this) with ERC20.approve
    function creditWithXpgfk(address pgfkBurner, uint256 tokenId) private {
        uint256 tokenGeneration = getTokenGeneration(tokenId);
        address xpgfkGen = _xpgfkGens[tokenGeneration];
        uint256 xpgfkRatio = _xpgfkRatios[xpgfkGen];
        address xpgfkGenOwner = _xpgfkGenOwners[tokenGeneration];

        ERC20Interface = ERC20(xpgfkGen);
        ERC20Interface.transferFrom(xpgfkGenOwner, pgfkBurner, xpgfkRatio);
    }

    function burnReceivedPgfk(uint256 tokenId) private {
        ERC721BurnableInterface = ERC721Burnable(_pgfk);
        ERC721BurnableInterface.burn(tokenId);
    }

    // Issues a PGFK that was preminted via Cargo
    function issuePremintedPgfk(address pgfkBuyer, uint256 tokenId) private {
        ERC721BurnableInterface = ERC721Burnable(_pgfk);
        ERC721BurnableInterface.transferFrom(_pgfkOwner, pgfkBuyer, tokenId);
    }

    /**
     * Callbacks for event-driven transfers of xPGFK and PGFK
     */

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public override returns (bytes4) {
        // the transaction must come from the pgfk contract
        require(msg.sender == _pgfk, "ParticleBridge: I reject your fake ERC721!");

        // Credit from with some xPGFK
        burnReceivedPgfk(tokenId);
        creditWithXpgfk(from, tokenId);

        emit Received(operator, from, tokenId, data, gasleft());

        return _retval;
    }

    function isXpgfkContract(address xpgfkContract) internal view returns (bool) {
        return _xpgfkRatios[xpgfkContract] != 0;
    }

    /**
     * PGFK Token Id Bridge Management
     */

    function currentTokenId() public view returns (uint256) {
        return _tokenId.current();
    }

    // All generations are the same for now
    function getTokenGeneration(uint256) public pure returns (uint256) {
        return 0;
    }

    /**
     * Admin Functions
     */

    // All PGFKs should be issued here or `issuePremintedPgfk`
    function adminIssuePremintedPgfk(address to) private {
        require(msg.sender == _owner, "ParticleBridge: You don't own me!");

        _tokenId.increment();
        uint256 newTokenId = _tokenId.current();

        ERC721BurnableInterface = ERC721Burnable(_pgfk);
        ERC721BurnableInterface.transferFrom(_pgfkOwner, to, newTokenId);
    }

    // We should never need to do this, but mistakes happen
    function updateCurrentTokenId(uint256 targetValue) public {
        require(msg.sender == _owner, "ParticleBridge: You don't own me!");
        while (_tokenId.current() < targetValue) {
            _tokenId.increment();
        }
        while (_tokenId.current() > targetValue) {
            _tokenId.decrement();
        }
    }

    // Update pgfk contract
    function setPgfkContract(address pgfkContract) public {
        require(msg.sender == _owner, "ParticleBridge: You don't own me!");
        _pgfk = pgfkContract;
    }

    // Update pgfk contract
    function setPgfkContractOwner(address pgfkContractOwner) public {
        require(msg.sender == _owner, "ParticleBridge: You don't own me!");
        _pgfkOwner = pgfkContractOwner;
    }

    // Update xpgfk contract
    function setXpgfkContractByGen(
        address xpgfkContract,
        uint256 generation,
        uint256 ratio
    ) public {
        require(msg.sender == _owner, "ParticleBridge: You don't own me!");
        _xpgfkGens[generation] = xpgfkContract;
        _xpgfkRatios[xpgfkContract] = ratio;
    }

    // Update xPGFK contract
    function setXpgfkContractOwnerByGen(address xpgfkContractOwner, uint256 generation)
        public
    {
        require(msg.sender == _owner, "ParticleBridge: You don't own me!");
        _xpgfkGenOwners[generation] = xpgfkContractOwner;
    }
}
