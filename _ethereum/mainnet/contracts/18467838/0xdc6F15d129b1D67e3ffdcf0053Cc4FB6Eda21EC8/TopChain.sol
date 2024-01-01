// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IInvestmentAgreement.sol";

import "./DealsRepo.sol";

library TopChain {

    enum CatOfNode {
        IndepMemberInQueue, // 0
        GroupRepInQueue,    // 1
        GroupMember,        // 2
        IndepMemberOnChain, // 3 
        GroupRepOnChain     // 4
    }

    struct Node {
        uint40 prev;
        uint40 next;
        uint40 ptr;
        uint64 amt;
        uint64 sum;
        uint8 cat;
    }

    struct Para {
        uint40 tail;
        uint40 head;
        uint32 maxQtyOfMembers;
        uint16 minVoteRatioOnChain;
        uint32 qtyOfSticks;
        uint32 qtyOfBranches;
        uint32 qtyOfMembers;
        uint16 para;
        uint16 argu;
    }

    struct Chain {
        // usrNo => Node
        mapping(uint256 => Node) nodes;
        Para para;
    }

    /* Node[0] {
        prev: tail;
        next: head;
        ptr: pending;
        amt: pending;
        sum: totalVotes;
        cat: basedOnPar;
    } */

    //#################
    //##   Modifier  ##
    //#################

    modifier memberExist(Chain storage chain, uint256 acct) {
        require(isMember(chain, acct), "TC.memberExist: acct not member");
        _;
    }

    //#################
    //##  Write I/O  ##
    //#################
    
    // ==== Options ====

    function setMaxQtyOfMembers(Chain storage chain, uint max) public {
        chain.para.maxQtyOfMembers = uint32(max);
    }

    function setMinVoteRatioOnChain(Chain storage chain, uint min) public {
        require(min < 5000, "minVoteRatioOnChain: overflow");
        chain.para.minVoteRatioOnChain = uint16(min);
    }

    function setVoteBase(
        Chain storage chain, 
        bool _basedOnPar
    ) public {
        chain.nodes[0].cat = _basedOnPar ? 1 : 0;
    }

    // ==== Node ====

    function addNode(Chain storage chain, uint acct) public {

        require(acct > 0, "TC.addNode: zero acct");

        Node storage n = chain.nodes[acct];

        if (n.ptr == 0) {
            require( maxQtyOfMembers(chain) == 0 ||
                qtyOfMembers(chain) < maxQtyOfMembers(chain),
                "TC.addNode: no vacance"
            );

            n.ptr = uint40(acct);

            _appendToQueue(chain, n, n.ptr);
            _increaseQtyOfMembers(chain);
        }
    }

    function delNode(Chain storage chain, uint acct) public {
        _carveOut(chain, acct);
        delete chain.nodes[acct];
        _decreaseQtyOfMembers(chain);        
    }

    // ==== ChangeAmt ====

    function increaseTotalVotes(
        Chain storage chain,
        uint deltaAmt, 
        bool isIncrease
    ) public {
        uint40 amt = uint40(deltaAmt);
        if (isIncrease) _increaseTotalVotes(chain, amt);
        else _decreaseTotalVotes(chain, amt);
    }

    function increaseAmt(
        Chain storage chain, 
        uint256 acct, 
        uint deltaAmt, 
        bool isIncrease
    ) public memberExist(chain, acct) {

        uint64 amt = uint64(deltaAmt);

        Node storage n = chain.nodes[acct];

        if (isIncrease) {
            n.amt += amt;
            n.sum += amt;
        } else {
            n.amt -= amt;
            n.sum -= amt;
        }

        if (n.cat == uint8(CatOfNode.GroupMember)) {

            Node storage r = chain.nodes[n.ptr];

            if (isIncrease) {

                r.sum += amt;
                
                if (r.cat == uint8(CatOfNode.GroupRepOnChain)) 
                    _move(chain, n.ptr, isIncrease);
                else if (_onChainTest(chain, r))
                    _upChainAndMove(chain, r, n.ptr);

            } else {

                r.sum -= amt;
                
                if (r.cat == uint8(CatOfNode.GroupRepOnChain)) {

                    if (!_onChainTest(chain, r)) 
                        _offChain(chain, r, n.ptr);
                    else _move(chain, n.ptr, isIncrease);

                }
            }

        } else if (_isOnChain(n)) {

            if (isIncrease) _move(chain, n.ptr, isIncrease);
            else {
                if (!_onChainTest(chain, n)) 
                    _offChain(chain, n, n.ptr);
                else _move(chain, n.ptr, isIncrease);
            }
        
        } else if(isIncrease && _onChainTest(chain, n))
            _upChainAndMove(chain, n, n.ptr);

    }

    // ==== Grouping ====

    function top2Sub(
        Chain storage chain,
        uint256 acct,
        uint256 root
    ) public memberExist(chain, root) {

        Node storage n = chain.nodes[acct];
        Node storage r = chain.nodes[root];

        require(acct != root, "TC.T2S: self grouping");
        require(_isIndepMember(n), "TC.T2S: not indepMember");
        require(_notGroupMember(r), "TC.T2S: leaf as root");

        _carveOut(chain, n.ptr);
        _vInsert(chain, n.ptr, uint40(root));
    }

    function sub2Top(Chain storage chain, uint256 acct) public {

        Node storage n = chain.nodes[acct];
        require(_isInGroup(n), "TC.S2T: not in a branch");

        _carveOut(chain, acct);

        n.sum = n.amt;
        n.ptr = uint40(acct);

        if (_onChainTest(chain, n)) _upChainAndMove(chain, n, n.ptr);
        else _appendToQueue(chain, n, n.ptr);
    }

    // ==== CarveOut ====

    function _branchOff(Chain storage chain, uint256 root) private {
        Node storage r = chain.nodes[root];

        if (_isOnChain(r)) {

            chain.nodes[r.next].prev = r.prev;
            chain.nodes[r.prev].next = r.next;

            _decreaseQtyOfBranches(chain);

        } else {

            if (r.prev > 0 && r.next > 0) {
                chain.nodes[r.next].prev = r.prev;
                chain.nodes[r.prev].next = r.next;
            }else if (r.prev == 0 && r.next == 0) {
                chain.para.tail = 0;
                chain.para.head = 0;
            }else if (r.next == 0) {
                chain.para.tail = r.prev;
                chain.nodes[r.prev].next = 0;
            } else if (r.prev == 0) {
                chain.nodes[r.next].prev = 0;
                chain.para.head = r.next;
            }

            _decreaseQtyOfSticks(chain);

        }
    }

    function _carveOut(Chain storage chain, uint acct)
        private
        memberExist(chain, acct)
    {
        Node storage n = chain.nodes[acct];

        if (_isIndepMember(n)) {

            _branchOff(chain, acct);
        
        } else if (_isGroupRep(n)) {

            if (n.cat == uint8(CatOfNode.GroupRepOnChain) || (n.prev > 0 && n.next > 0)) {

                chain.nodes[n.prev].next = n.ptr;
                chain.nodes[n.next].prev = n.ptr;

            } else {

                if (n.prev == 0 && n.next == 0) {
                    chain.para.tail = n.ptr;
                    chain.para.head = n.ptr;
                } else if (n.next == 0) {
                    chain.para.tail = n.ptr;
                    chain.nodes[n.prev].next = n.ptr;
                } else if (n.prev == 0) {
                    chain.nodes[n.next].prev = n.ptr;
                    chain.para.head = n.ptr;
                }

            }

            Node storage d = chain.nodes[n.ptr];

            d.ptr = d.next;
            d.prev = n.prev;
            d.next = n.next;

            if (d.ptr > 0) {
                uint40 cur = d.ptr;
                while (cur > 0) {
                    chain.nodes[cur].ptr = n.ptr;
                    cur = chain.nodes[cur].next;
                }
                d.cat = n.cat;
            } else {
                d.ptr = n.ptr;
                d.cat = n.cat == uint8(CatOfNode.GroupRepInQueue) 
                    ? uint8(CatOfNode.IndepMemberInQueue) 
                    : uint8(CatOfNode.IndepMemberOnChain);
            }

            d.sum = n.sum - n.amt;

            _offChainCheck(chain, d, n.ptr);

        } else if (_isGroupMember(n)) {

            Node storage u = chain.nodes[n.prev];

            if (n.next > 0) chain.nodes[n.next].prev = n.prev;

            if (u.cat == uint8(CatOfNode.GroupMember)) u.next = n.next;
            else if (n.next > 0) {
                u.ptr = n.next;
            } else {
                u.ptr = n.ptr;
                u.cat = u.cat == uint8(CatOfNode.GroupRepInQueue) 
                    ? uint8(CatOfNode.IndepMemberInQueue) 
                    : uint8(CatOfNode.IndepMemberOnChain);
            }

            Node storage r = chain.nodes[n.ptr];

            r.sum -= n.amt;

            _offChainCheck(chain, r, n.ptr);

        }
    }

    function _offChainCheck(
        Chain storage chain,
        Node storage r,
        uint40 acct
    ) private {
        if (_isOnChain(r)) {
            if (_onChainTest(chain, r)) _move(chain, acct, false);
            else _offChain(chain, r, acct);                
        }
    }

    // ==== Insert ====

    function _hInsert(
        Chain storage chain,
        uint acct,
        uint prev,
        uint next
    ) private {
        Node storage n = chain.nodes[acct];

        chain.nodes[prev].next = uint40(acct);
        n.prev = uint40(prev);

        chain.nodes[next].prev = uint40(acct);
        n.next = uint40(next);
    }

    function _vInsert(
        Chain storage chain,
        uint40 acct,
        uint40 root
    ) private {
        Node storage n = chain.nodes[acct];
        Node storage r = chain.nodes[root];

        if (_isIndepMember(r)) {
            r.cat = r.cat == uint8(CatOfNode.IndepMemberInQueue) 
                ? uint8(CatOfNode.GroupRepInQueue) 
                : uint8(CatOfNode.GroupRepOnChain);
            n.next = 0;
        } else if (_isGroupRep(r)) {
            n.next = r.ptr;
            chain.nodes[n.next].prev = acct;
        }

        n.prev = root;
        n.ptr = root;

        n.cat = uint8(CatOfNode.GroupMember);

        r.ptr = acct;
        r.sum += n.amt;

        if (_isOnChain(r)) _move(chain, root, true);
        else if (_onChainTest(chain, r)) {
            _upChainAndMove(chain, r, root);
        }
    }

    // ==== Move ====

    function _move(
        Chain storage chain,
        uint acct,
        bool increase
    ) private {
        Node storage n = chain.nodes[acct];

        (uint256 prev, uint256 next) = getPos(
            chain,
            n.sum,
            n.prev,
            n.next,
            increase
        );

        if (next != n.next || prev != n.prev) {
            _branchOff(chain, acct); 
            _hInsert(chain, acct, prev, next);
        }
    }

    // ==== Chain & Queue ====

    function _appendToQueue(
        Chain storage chain,
        Node storage n,
        uint40 acct
    ) private {

        if (chain.para.qtyOfSticks > 0) {
            chain.nodes[chain.para.tail].next = acct;
        } else {
            chain.para.head = acct;
        }

        n.prev = chain.para.tail;
        n.next = 0;

        chain.para.tail = acct;

        if (_isOnChain(n)) n.cat -= 3;

        _increaseQtyOfSticks(chain);
    }

    function _appendToChain(
        Chain storage chain,
        Node storage n,
        uint40 acct
    ) private {
        n.prev = chain.nodes[0].prev;
        chain.nodes[n.prev].next = acct;
        chain.nodes[0].prev = acct;
        n.next = 0;

        if (_isInQueue(n)) n.cat += 3;

        _increaseQtyOfBranches(chain);
    }

    function _onChainTest(
        Chain storage chain,
        Node storage r
    ) private view returns(bool) {
        return uint(r.sum) * 10000 >= uint(totalVotes(chain)) * minVoteRatioOnChain(chain);
    }

    function _upChainAndMove(
        Chain storage chain,
        Node storage n,
        uint40 acct
    ) private {
        _trimChain(chain);
        _branchOff(chain, acct);
        _appendToChain(chain, n, acct);
        _move(chain, acct, true);

    }

    function _trimChain(
        Chain storage chain
    ) private {

        uint40 cur = chain.nodes[0].prev;
        
        while (cur > 0) {
            Node storage t = chain.nodes[cur];
            uint40 prev = t.prev;
            if (!_onChainTest(chain, t))
                _offChain(chain, t, cur);
            else break;
            cur = prev;
        }
    }

    function _offChain(
        Chain storage chain,
        Node storage n,
        uint40 acct
    ) private {
        _branchOff(chain, acct);
        _appendToQueue(chain, n, acct);                            
    }

    // ---- Categories Of Node ----

    function _isOnChain(
        Node storage n
    ) private view returns (bool) {
        return n.cat > 2;
    }

    function _isInQueue(
        Node storage n
    ) private view returns (bool) {
        return n.cat < 2;
    }

    function _isIndepMember(
        Node storage n
    ) private view returns (bool) {
        return n.cat % 3 == 0;
    }

    function _isInGroup(
        Node storage n
    ) private view returns (bool) {
        return n.cat % 3 > 0;
    }

    function _isGroupRep(
        Node storage n
    ) private view returns (bool) {
        return n.cat % 3 == 1;
    }

    function _isGroupMember(
        Node storage n
    ) private view returns (bool) {
        return n.cat == uint8(CatOfNode.GroupMember);
    }

    function _notGroupMember(
        Node storage n
    ) private view returns (bool) {
        return n.cat % 3 < 2;
    }

    // ==== setting ====

    function _increaseQtyOfBranches(Chain storage chain) private {
        chain.para.qtyOfBranches++;
    }

    function _increaseQtyOfMembers(Chain storage chain) private {
        chain.para.qtyOfMembers++;
    }

    function _increaseQtyOfSticks(Chain storage chain) private {
        chain.para.qtyOfSticks++;
    }

    function _increaseTotalVotes(Chain storage chain, uint64 deltaAmt) private {
        chain.nodes[0].sum += deltaAmt;
    }

    function _decreaseQtyOfBranches(Chain storage chain) private {
        chain.para.qtyOfBranches--;
    }

    function _decreaseQtyOfMembers(Chain storage chain) private {
        chain.para.qtyOfMembers--;
    }

    function _decreaseQtyOfSticks(Chain storage chain) private {
        chain.para.qtyOfSticks--;
    }

    function _decreaseTotalVotes(Chain storage chain, uint64 deltaAmt) private {
        chain.nodes[0].sum -= deltaAmt;
    }

    //##################
    //##    读接口    ##
    //##################

    function isMember(Chain storage chain, uint256 acct)
        public
        view
        returns (bool)
    {
        return chain.nodes[acct].ptr != 0;
    }

    // ==== Zero Node ====

    function tail(Chain storage chain) public view returns (uint40) {
        return chain.nodes[0].prev;
    }

    function head(Chain storage chain) public view returns (uint40) {
        return chain.nodes[0].next;
    }

    function totalVotes(Chain storage chain) public view returns (uint64) {
        return chain.nodes[0].sum;
    }

    function basedOnPar(Chain storage chain) public view returns (bool) {
        return chain.nodes[0].cat == 1;
    }

    // ---- Para ----

    function headOfQueue(Chain storage chain)
        public
        view
        returns (uint40)
    {
        return  chain.para.head;
    }

    function tailOfQueue(Chain storage chain)
        public
        view
        returns (uint40)
    {
        return  chain.para.tail;
    }

    function maxQtyOfMembers(Chain storage chain)
        public
        view
        returns (uint32)
    {
        return chain.para.maxQtyOfMembers; 
    }

    function minVoteRatioOnChain(Chain storage chain)
        public
        view
        returns (uint16)
    {
        uint16 min = chain.para.minVoteRatioOnChain;
        return min > 0 ? min : 500; 
    }

    function qtyOfBranches(Chain storage chain) public view returns (uint32) {
        return chain.para.qtyOfBranches;
    }

    function qtyOfGroups(Chain storage chain) public view returns (uint32) {
        return chain.para.qtyOfBranches + chain.para.qtyOfSticks;
    }

    function qtyOfTopMembers(Chain storage chain) 
        public view 
        returns(uint qty) 
    {
        uint cur = chain.nodes[0].next;

        while(cur > 0) {
            qty++;
            cur = nextNode(chain, cur);
        }
    }

    function qtyOfMembers(Chain storage chain) public view returns (uint32) {
        return chain.para.qtyOfMembers;
    }

    // ==== locate position ====

    function getPos(
        Chain storage chain,
        uint256 amount,
        uint256 prev,
        uint256 next,
        bool increase
    ) public view returns (uint256, uint256) {
        if (increase)
            while (prev > 0 && chain.nodes[prev].sum < amount) {
                next = prev;
                prev = chain.nodes[prev].prev;
            }
        else
            while (next > 0 && chain.nodes[next].sum > amount) {
                prev = next;
                next = chain.nodes[next].next;
            }

        return (prev, next);
    }

    function nextNode(Chain storage chain, uint256 acct)
        public view returns (uint256 next)
    {
        Node storage n = chain.nodes[acct];

        if (_isIndepMember(n)) {
            next = n.next;
        } else if (_isGroupRep(n)) {
            next = n.ptr;
        } else if (_isGroupMember(n)) {
            next = (n.next > 0) ? n.next : chain.nodes[n.ptr].next;
        }
    }

    function getNode(Chain storage chain, uint256 acct)
        public view returns (Node memory n)
    {
        n = chain.nodes[acct];
    }

    // ==== group ====

    function rootOf(Chain storage chain, uint256 acct)
        public
        view
        memberExist(chain, acct)
        returns (uint40 group)
    {
        Node storage n = chain.nodes[acct];
        group = (n.cat == uint8(CatOfNode.GroupMember)) ? n.ptr : uint40(acct) ;
    }

    function deepOfBranch(Chain storage chain, uint256 acct)
        public
        view
        memberExist(chain, acct)
        returns (uint256 deep)
    {
        Node storage n = chain.nodes[acct];

        if (_isIndepMember(n)) deep = 1;
        else if (_isGroupRep(n)) deep = _deepOfBranch(chain, acct);
        else deep = _deepOfBranch(chain, n.ptr);
    }

    function _deepOfBranch(Chain storage chain, uint256 root)
        private
        view
        returns (uint256 deep)
    {
        deep = 1;

        uint40 next = chain.nodes[root].ptr;

        while (next > 0) {
            deep++;
            next = chain.nodes[next].next;
        }
    }

    function votesOfGroup(Chain storage chain, uint256 acct)
        public
        view
        returns (uint64 votes)
    {
        uint256 group = rootOf(chain, acct);
        votes = chain.nodes[group].sum;
    }

    function membersOfGroup(Chain storage chain, uint256 acct)
        public
        view
        returns (uint256[] memory list)
    {
        uint256 cur = rootOf(chain, acct);
        uint256 len = deepOfBranch(chain, acct);

        list = new uint256[](len);
        uint256 i = 0;

        while (i < len) {
            list[i] = cur;
            cur = nextNode(chain, cur);
            i++;
        }
    }

    function affiliated(
        Chain storage chain,
        uint256 acct1,
        uint256 acct2
    )
        public
        view
        memberExist(chain, acct1)
        memberExist(chain, acct2)
        returns (bool)
    {
        Node storage n1 = chain.nodes[acct1];
        Node storage n2 = chain.nodes[acct2];

        return n1.ptr == n2.ptr || n1.ptr == acct2 || n2.ptr == acct1;
    }

    // ==== members ====

    function topMembersList(Chain storage chain)
        public view
        returns (uint256[] memory list)
    {
        uint256 len = qtyOfTopMembers(chain);
        list = new uint[](len);

        len = 0;
        uint cur = chain.nodes[0].next;

        _seqListOfQueue(chain, list, cur, len);
    }

    function sortedMembersList(Chain storage chain)
        public
        view
        returns (uint256[] memory list)
    {
        uint256 len = qtyOfMembers(chain);
        list = new uint[](len);

        uint cur = chain.nodes[0].next;
        len = 0;

        len = _seqListOfQueue(chain, list, cur, len);

        cur = chain.para.head;
        _seqListOfQueue(chain, list, cur, len);
    }

    function _seqListOfQueue(
        Chain storage chain,
        uint[] memory list,
        uint cur,
        uint i
    ) private view returns (uint) {
        while (cur > 0) {
            list[i] = cur;
            cur = nextNode(chain, cur);
            i++;
        }
        return i;
    }

    // ==== Backup / Restore ====

    function getSnapshot(Chain storage chain)
        public view
        returns (Node[] memory list, Para memory para)
    {
        para = chain.para;

        uint256 len = qtyOfMembers(chain);
        list = new Node[](len + 1);

        list[0] = chain.nodes[0];

        uint256 cur = chain.nodes[0].next;
        len = 1;
        len = _backupNodes(chain, list, cur, len);

        cur = para.head;
        _backupNodes(chain, list, cur, len);
    }

    function _backupNodes(
        Chain storage chain,
        Node[] memory list,
        uint cur,
        uint i
    ) private view returns (uint) {
        while (cur > 0) {
            list[i] = chain.nodes[cur];
            cur = nextNode(chain, cur);
            i++;
        }
        return i;
    }

    function restoreChain(
        Chain storage chain, 
        Node[] memory list, 
        Para memory para
    ) public {

        chain.nodes[0] = list[0];
        chain.para = para;

        uint256 cur = list[0].next;
        uint256 i = 1;
        i = _restoreNodes(chain, list, cur, i);

        cur = para.head;
        _restoreNodes(chain, list, cur, i);
    }

    function _restoreNodes(
        Chain storage chain,
        Node[] memory list,
        uint cur,
        uint i
    ) private returns (uint) {
        while (cur > 0) {
            chain.nodes[cur] = list[i];
            cur = nextNode(chain, cur);
            i++;
        }
        return i;
    }

    // ==== MockDeals ====

    function mockDealsOfIA(
        Chain storage chain,
        IInvestmentAgreement _ia
    ) public {
        uint[] memory seqList = _ia.getSeqList();

        uint256 len = seqList.length;

        while (len > 0) {
            DealsRepo.Deal memory deal = _ia.getDeal(seqList[len-1]);

            uint64 amount = basedOnPar(chain) ? deal.body.par : deal.body.paid;

            if (deal.head.seller > 0) {
                mockDealOfSell(chain, deal.head.seller, amount);
            }

            mockDealOfBuy(chain, deal.body.buyer, deal.body.groupOfBuyer, amount);

            len--;
        }
    }

    function mockDealOfSell(
        Chain storage chain, 
        uint256 seller, 
        uint amount
    ) public {
        increaseAmt(chain, seller, amount, false);
        
        if (chain.nodes[seller].amt == 0)
            delNode(chain, seller);
    }

    function mockDealOfBuy(
        Chain storage chain, 
        uint256 buyer, 
        uint256 group,
        uint amount
    ) public {
        addNode(chain, buyer);

        increaseAmt(chain, buyer, amount, true);

        if (rootOf(chain, buyer) != group)
            top2Sub(chain, buyer, group);
    }
}