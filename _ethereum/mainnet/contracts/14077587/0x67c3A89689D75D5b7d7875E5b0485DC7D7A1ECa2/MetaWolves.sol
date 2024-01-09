//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";

contract MetaWolves is ERC721Enumerable {
    using Strings for uint256;

    struct BaseURIRoot {
        uint256 start;
        string baseURI;
    }
    BaseURIRoot[] public baseURIRoots;

    struct MintLimit {
        uint32 expireTime;
        uint32 limit;
        uint32 globalLimit;
    }
    MintLimit[] public mintLimits;
    uint32 private _mintLimitIndex = 0;
    function mintLimitIndex() public view returns (uint32) {
        uint32 mintLimitIndex_ = _mintLimitIndex;
        for(; mintLimits[mintLimitIndex_].expireTime <= block.timestamp && mintLimits[mintLimitIndex_].expireTime != 0; mintLimitIndex_++){}
        return mintLimitIndex_;
    }

    struct Minted {
        uint32 mintLimitIndex;
        uint32 minted;
    }
    mapping(address => Minted) public minted;
    modifier haveLimit (uint256 amount) {
        uint32 mintLimitIndex_ = _mintLimitIndex;
        for(; mintLimits[mintLimitIndex_].expireTime <= block.timestamp && mintLimits[mintLimitIndex_].expireTime != 0; mintLimitIndex_++){}
        _mintLimitIndex = mintLimitIndex_;
        address global = address(this);

        require((minted[msg.sender].mintLimitIndex < mintLimitIndex_
            || minted[msg.sender].minted + amount <= mintLimits[mintLimitIndex_].limit)
            && (minted[global].minted + amount <= mintLimits[mintLimitIndex_].globalLimit
            || minted[global].mintLimitIndex < mintLimitIndex_)
        , "Cannot mint more than limit");

        if (minted[msg.sender].mintLimitIndex < mintLimitIndex_) {
            minted[msg.sender].minted = uint32(amount);
            minted[msg.sender].mintLimitIndex = mintLimitIndex_;
        } else {
            minted[msg.sender].minted += uint32(amount);
        }

        if (minted[global].mintLimitIndex < mintLimitIndex_) {
            minted[global].minted = uint32(amount);
            minted[global].mintLimitIndex = mintLimitIndex_;
        } else {
            minted[global].minted += uint32(amount);
        }
        _;
    }

    uint256 public maxSupply = 888;

    string public contractURI = "ipfs://bafkreibvt6rebhkukixa52cofpvnmcucdz7mnearovabrvuo37ajwib25q";

    uint256 public price = 0.22 ether;
    modifier paid(uint256 amount) {
        require(msg.value >= price * amount, "Amount paid not enough");
        _;
    }

    mapping(address => bool) public operators;
    modifier onlyOperator() {
        require(operators[msg.sender], "Not an operator");
        _;
    }

    constructor () ERC721("MetaWolves", "MWL") {
        mintLimits.push(MintLimit(1643205600, 1, 63));
        mintLimits.push(MintLimit(1643212800, 215, 215));
        mintLimits.push(MintLimit(0, 0, 0));
        baseURIRoots.push(BaseURIRoot(0, "ipfs://bafybeihhv63xnmjnjl4zabasirvzze7keoxpse7yqwo6soaqbmgy64wyna/"));
        baseURIRoots.push(BaseURIRoot(6, "ipfs://bafkreihmydpaj4yk72mxeqe4et476rrxcp7fjhzjbiqhvcs3y6mcaqjuym/?"));
        operators[msg.sender] = true;
    }

    function _safeMint(address to, uint256 tokenId) internal override {
        super._safeMint(to, tokenId);
        require(totalSupply() <= maxSupply);
    }

    function devMint(uint256 amount) external onlyOperator {
        devMint(amount, msg.sender);
    }

    function devMint(uint256 amount, address to) public onlyOperator {
        for (uint256 i = 0; i < amount; i++) _safeMint(to, totalSupply() + 1);
    }

    function setMintLimit(uint256 index, MintLimit calldata newMintLimit) external onlyOperator {
        // incorrect index will revert
        require(index == 0 || newMintLimit.expireTime > mintLimits[index - 1].expireTime, "expireTime of mint limit is restrictly increasing");
        if (index == mintLimits.length) {
            mintLimits.push(newMintLimit);
        } else {
            require(
                mintLimits.length - 1 == index
                || newMintLimit.expireTime < mintLimits[index + 1].expireTime
                || mintLimits[index + 1].expireTime == 0
            , "expireTime of mint limit is restrictly increasing");
            mintLimits[index] = newMintLimit;
        }
    }

    function setNextMintLimits(uint32[] calldata currentExpire, uint32[] calldata nextLimit, uint32[] calldata globalLimit) external onlyOperator {
        uint256 length = currentExpire.length;
        require(length == nextLimit.length && length == globalLimit.length, "Arg amount not matched");
        require(mintLimits[mintLimits.length - 2].expireTime < currentExpire[0], "expireTime of mint limit is restrictly increasing");
        mintLimits[mintLimits.length - 1].expireTime = currentExpire[0];
        for (uint256 i = 0; i < length; i++) {
            require(mintLimits[mintLimits.length - 2].expireTime < currentExpire[i], "expireTime of mint limit is restrictly increasing");
            mintLimits.push(
                MintLimit(
                    i + 1 == length ? 0 : currentExpire[i + 1],
                    nextLimit[i],
                    globalLimit[i]
                )
            );
        }
    }

    function setBaseURI(uint256 index, BaseURIRoot calldata baseURIRoot) external onlyOperator {
        // incorrect index will revert
        require(baseURIRoot.start > baseURIRoots[index - 1].start, "Start of base URI root is restrictly increasing");
        if (index == baseURIRoots.length) {
            baseURIRoots.push(baseURIRoot);
        } else {
            require(baseURIRoots.length - 1 == index || baseURIRoot.start < baseURIRoots[index + 1].start, "Start of base URI root is restrictly increasing");
            baseURIRoots[index] = baseURIRoot;
        }
    }

    function setPrice(uint256 newPrice) external onlyOperator {
        price = newPrice;
    }
    
    function setOperator(address addr, bool state) external onlyOperator {
        operators[addr] = state;
    }

    function mint(uint256 amount) external payable paid(amount) haveLimit(amount) {
        for (uint256 i = 0; i < amount; i++) _safeMint(msg.sender, totalSupply() + 1);
    }

    // follow sale rule without paying
    function devFreeMint(uint256 amount) external onlyOperator haveLimit(amount) {
        for (uint256 i = 0; i < amount; i++) _safeMint(msg.sender, totalSupply() + 1);
    }

    function withdraw(uint256 amount) external onlyOperator {
        if (amount > address(this).balance) amount = address(this).balance;
        payable(msg.sender).transfer(amount);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        uint256 i = 1;
        for (; i < baseURIRoots.length && baseURIRoots[i].start <= tokenId; i++) {}
        string memory baseURI = baseURIRoots[i - 1].baseURI;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function remainMintable(address minter) external view returns (uint256) {
        uint32 mintLimitIndex_ = mintLimitIndex();
        address global = address(this);

        uint256 globalMintable = minted[global].mintLimitIndex < mintLimitIndex_ 
            ? mintLimits[mintLimitIndex_].globalLimit
            : mintLimits[mintLimitIndex_].globalLimit - minted[global].minted;
        uint256 personMintable = minted[minter].mintLimitIndex < mintLimitIndex_ 
            ? mintLimits[mintLimitIndex_].limit
            : mintLimits[mintLimitIndex_].limit - minted[minter].minted;

        return globalMintable < personMintable ? globalMintable : personMintable;
    }

    function mintLimitByTime(uint256 ts) external view returns (MintLimit memory) {
        uint256 i = 0;
        for (; i < mintLimits.length && (mintLimits[i].expireTime < ts && mintLimits[i].expireTime != 0); i++) {}
        return mintLimits[i];
    }
}
