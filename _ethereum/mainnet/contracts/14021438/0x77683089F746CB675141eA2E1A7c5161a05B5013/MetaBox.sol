// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "./InitializableOwner.sol";
import "./Random.sol";
import "./IMetaNft.sol";
import "./console.sol";


contract MetaBox is InitializableOwner {
    struct BoxFactory {
        uint256 id;
        string name;
        IMetaNft nft;
        uint256 limit;
        uint256 minted;
        uint256[] limits;
        uint256[] minteds;
        uint256 mode;       // 0 - serial 1 - single
        uint256[] exchange_price;
        uint256 price;
        uint256 createdTime;
        uint256 startTime;
    }

    struct BoxView {
        uint256 id;
        uint256 factoryid;
        uint256 level;
        uint256 tokenId;
        bool exchanged;
        uint256 openTime;
        address owner;
    }

    event NewBoxFactory(
        uint256 indexed id,
        string name,
        IMetaNft nft,
        uint256 limit,
        uint256[] limits,
        uint256 mode,
        uint256 price,
        uint256 createdTime,
        uint256 startTime
    );

    event OpenBox(uint256 indexed id, uint256 boxId, uint256 level, uint256 tokenId);

    uint256 private _boxFactoriesId = 0;
    uint256 private _boxId = 1e3;

    mapping(uint256 => BoxView) private _boxes; // boxId: BoxView
    mapping(uint256 => BoxFactory) private _boxFactories; // factoryId: BoxFactory
    mapping(address => uint256[]) private _boxeOwners;  // buyer: boxIds
    uint256 _seed;

    string private _name;
    string private _symbol;

    constructor() public {
        super._initialize();

        _name = "MetaBox";
        _symbol = "MetaBox";
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function addBoxFactory(
        string memory name_,
        IMetaNft nft_,
        uint256[] memory limits,
        uint256 mode,
        uint256[] memory exchange_price,
        uint256 price,
        uint256 startTime
    ) public onlyOwner returns (uint256) {
        _boxFactoriesId++;

        uint256 limit;
        uint256[] memory minteds = new uint256[](limits.length);
        for (uint i=0; i<limits.length; i++) {
            limit += limits[i];
        }

        BoxFactory memory box;
        box.id = _boxFactoriesId;
        box.name = name_;
        box.nft = nft_;
        box.limit = limit;
        box.limits = limits;
        box.minteds = minteds;
        box.mode = mode;
        box.exchange_price = exchange_price;
        box.price = price;
        box.createdTime = block.timestamp;
        box.startTime  = block.timestamp + startTime;

        _boxFactories[_boxFactoriesId] = box;

        emit NewBoxFactory(
            _boxFactoriesId,
            name_,
            nft_,
            limit,
            limits,
            mode,
            price,
            block.timestamp,
            box.startTime
        );
        return _boxFactoriesId;
    }

    function getFactory(uint256 factoryId) public view
    returns (BoxFactory memory)
    {
        return _boxFactories[factoryId];
    }

    function getBoxView(uint256 boxId) public view returns (BoxView memory) {
        return _boxes[boxId];
    }

    function getLevel(uint256 seed, uint256[] memory limits, uint256[] memory minteds) internal view returns(uint256) {
        uint256 left = 0;
        for (uint i=0; i<limits.length; i++) {
            left += (limits[i] - minteds[i]);
        }
        require(left > 0, "All minted");

        uint256 val = seed % left;
        uint256 limitCount=0;
        for (uint i=0; i<limits.length; i++) {
            limitCount += (limits[i] - minteds[i]);
            console.log("limitCount %s", limitCount);
            if (val < limitCount) {
                return i;
            }
        }
    }

    function buy(uint256 factoryId) public payable {
        BoxFactory storage factory = _boxFactories[factoryId];
        require(factory.limits.length != 0, "box not found");
        require(block.timestamp >= factory.startTime, "Factory inactivate");

        if(factory.limit > 0) {
            require((factory.limit - factory.minted) >= 1, "Over the limit");
        }
        factory.minted += 1;

        uint256 price = factory.price;
        require(msg.value >= price, "Not enough token");

        _boxId++;
        BoxView memory box;
        box.id = _boxId;
        box.factoryid = factoryId;
        box.level=0;
        box.exchanged=false;
        box.owner = msg.sender;
        box.openTime = block.timestamp;
        uint256 level = _openBox(box, factory);
        factory.minteds[level] += 1;
        uint256 startIndex=0;
        for (uint256 i=0;i<level;i++) {
            startIndex += factory.limits[i];
        }
        uint256 tokenId = factory.nft.mint(msg.sender, level, startIndex, factory.minteds[level]);
        box.level = level;
        box.tokenId=tokenId;
        _boxes[_boxId] = box;
        uint256[] storage boxids = _boxeOwners[msg.sender];
        boxids.push(_boxId);
        emit OpenBox(factory.id, box.id, level, tokenId);
    }

    function _openBox(BoxView memory box, BoxFactory memory factory) internal returns (uint256) {
        require(isContract(msg.sender) == false && tx.origin == msg.sender, "Prohibit contract calls");
        _upSeed(box.id);

        uint256 seed = Random.computerSeed() / _seed;

        uint256 level = getLevel(seed, factory.limits, factory.minteds);

        return level;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function _upSeed(uint256 val) internal {
        _seed =  (_seed +  val / block.timestamp);
        if (_seed > 50000) {
            _seed %= 50000;
        }
    }

    function upSeed(uint256 val) public onlyOwner {
        _upSeed(val);
    }
    
    function getSeed() public view onlyOwner returns(uint256) {
        return _seed;
    }

    function getBoxes(address account, uint256 factoryid) public view returns (BoxView[] memory) {
        uint256 len = _boxeOwners[account].length;
        BoxView[] memory boxes = new BoxView[](len);
        uint256 index=0;
        for (uint256 i=0;i<_boxeOwners[account].length;i++) {
            uint256 boxid=_boxeOwners[account][i];
            BoxView memory box = _boxes[boxid];
            console.log("%s %s", factoryid, box.id);
            if (factoryid != 0 && box.factoryid==factoryid) {
                boxes[index] = box;
                index += 1;
            } else {
                boxes[i] = box;
            }
        }
        return boxes;
    } 

    function exchange(uint256 factoryid, uint256[] memory boxids) public {
        BoxFactory memory factory = _boxFactories[factoryid];
        require(block.timestamp >= factory.startTime, "Factory inactivate");
        if (boxids.length == 1) {
            require(factory.mode == 1, "Factory mode is serial");
            _exchange_single(factory, boxids[0]);
        } else {
            require(factory.mode == 0, "Factory mode is single");
            _exchange_serial(factory, boxids);
        }
    }

    function _exchange_single(BoxFactory memory factory, uint256 boxid) internal {
        BoxView storage box = _boxes[boxid];
        require(box.owner == msg.sender, "Not box owner");
        require(box.exchanged == false, "Exchanged");
        _remove_boxid(boxid);
        box.owner=owner();
        box.exchanged=true;
        factory.nft.transferFrom(msg.sender, owner(), box.tokenId);
        uint256[] storage ownerBoxids=_boxeOwners[owner()];
        ownerBoxids.push(boxid);
        payable(msg.sender).transfer(factory.exchange_price[box.level]);
    }

    function _exchange_serial(BoxFactory memory factory, uint256[] memory boxids) internal {
        require(boxids.length == factory.limits.length, "Boxid count not enough");
        uint256 indexSum=0;
        uint256 levelSum=0;
        for (uint256 i=0; i<boxids.length; i++) {
            BoxView storage box = _boxes[boxids[i]];
            require(box.owner == msg.sender, "Not box owner");
            require(box.exchanged == false, "Exchanged");
            box.owner = owner();
            box.exchanged=true;
            _remove_boxid(boxids[i]);
            factory.nft.transferFrom(msg.sender, owner(), box.tokenId);
            uint256[] storage ownerBoxids=_boxeOwners[owner()];
            ownerBoxids.push(boxids[i]);
            indexSum += i;
            levelSum += box.level;
        }
        require(indexSum == levelSum, "Invalid boxids");
        payable(msg.sender).transfer(factory.exchange_price[0]);
    }

    function _remove_boxid(uint256 boxid) internal {
        uint256[] storage boxids = _boxeOwners[msg.sender];
        uint256[] memory newBoxIds = new uint256[](boxids.length-1);

        bool flag=false;
        for (uint256 i=0;i<boxids.length;i++) {
            if (flag == false && boxids[i] == boxid) {
                flag = true;
            }
            if (flag == true) {
                if (i+1 < boxids.length) {
                    newBoxIds[i] = boxids[i+1];
                }
            } else {
                newBoxIds[i] = boxids[i];
            }
        }
        _boxeOwners[msg.sender] = newBoxIds;
    }

    function resetLimits(uint256 factoryid, uint256[] memory newLimits) public onlyOwner {
        BoxFactory storage factory = _boxFactories[factoryid];
        require(factory.startTime > 0, "Factory inactivate");
        require(factory.limits.length == newLimits.length, "Invalid new limits");

        uint256 newLimit = 0;
        for (uint256 i=0;i<newLimits.length;i++) {
            require(newLimits[i] >= factory.minteds[i], "Cannt less minted");
            newLimit += newLimits[i];
        }

        factory.limits = newLimits;
        factory.limit = newLimit;
    }

    function resetExchangePrices(uint256 factoryid, uint256[] memory newExchangePrices) public onlyOwner {
        BoxFactory storage factory = _boxFactories[factoryid];
        require(factory.startTime > 0, "Factory inactivate");
        require(factory.exchange_price.length == newExchangePrices.length, "Invalid new price");

        factory.exchange_price = newExchangePrices;
    }

    function withdraw(address reciver, uint256 amount) public onlyOwner {
        require(reciver != address(0), "Zero address");

        payable(reciver).transfer(amount);
    }

    receive() payable external {}
}
