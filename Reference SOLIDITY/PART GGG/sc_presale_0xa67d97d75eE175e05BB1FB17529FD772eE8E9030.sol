/**********************************************************************
*These solidity codes have been obtained from Etherscan for extracting
*the smartcontract related info.
*The data will be used by MATRIX AI team as the reference basis for
*MATRIX model analysis,extraction of contract semantics,
*as well as AI based data analysis, etc.
**********************************************************************/
pragma solidity ^0.4.10;

contract Token {
    
    mapping (address => uint256) public balanceOf;
    mapping (uint256 => address) public addresses;
    mapping (address => bool) public addressExists;
    mapping (address => uint256) public addressIndex;
    uint256 public numberOfAddress = 0;
    
    string public physicalString;
    string public cryptoString;
    
    bool public isSecured;
    string public name;
    string public symbol;
    uint256 public totalSupply;
    bool public canMintBurn;
    uint256 public txnTax;
    uint256 public holdingTax;
    //In Weeks, on Fridays
    uint256 public holdingTaxInterval;
    uint256 public lastHoldingTax;
    uint256 public holdingTaxDecimals = 2;
    bool public isPrivate;
    
    address public owner;
    
    function Token(string n, string a, uint256 totalSupplyToUse, bool isSecured, bool cMB, string physical, string crypto, uint256 txnTaxToUse, uint256 holdingTaxToUse, uint256 holdingTaxIntervalToUse, bool isPrivateToUse) {
        name = n;
        symbol = a;
        totalSupply = totalSupplyToUse;
        balanceOf[msg.sender] = totalSupplyToUse;
        isSecured = isSecured;
        physicalString = physical;
        cryptoString = crypto;
        canMintBurn = cMB;
        owner = msg.sender;
        txnTax = txnTaxToUse;
        holdingTax = holdingTaxToUse;
        holdingTaxInterval = holdingTaxIntervalToUse;
        if(holdingTaxInterval!=0) {
            lastHoldingTax = now;
            while(getHour(lastHoldingTax)!=21) {
                lastHoldingTax -= 1 hours;
            }
            while(getWeekday(lastHoldingTax)!=5) {
                lastHoldingTax -= 1 days;
            }
            lastHoldingTax -= getMinute(lastHoldingTax) * (1 minutes) + getSecond(lastHoldingTax) * (1 seconds);
        }
        isPrivate = isPrivateToUse;
        
        addAddress(owner);
    }
    
    function transfer(address _to, uint256 _value) payable {
        chargeHoldingTax();
        if (balanceOf[msg.sender] < _value) throw;
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;
        if (msg.sender != owner && _to != owner && txnTax != 0) {
            if(!owner.send(txnTax)) {
                throw;
            }
        }
        if(isPrivate && msg.sender != owner && !addressExists[_to]) {
            throw;
        }
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        addAddress(_to);
        Transfer(msg.sender, _to, _value);
    }
    
    function changeTxnTax(uint256 _newValue) {
        if(msg.sender != owner) throw;
        txnTax = _newValue;
    }
    
    function mint(uint256 _value) {
        if(canMintBurn && msg.sender == owner) {
            if (balanceOf[msg.sender] + _value < balanceOf[msg.sender]) throw;
            balanceOf[msg.sender] += _value;
            totalSupply += _value;
            Transfer(0, msg.sender, _value);
        }
    }
    
    function burn(uint256 _value) {
        if(canMintBurn && msg.sender == owner) {
            if (balanceOf[msg.sender] < _value) throw;
            balanceOf[msg.sender] -= _value;
            totalSupply -= _value;
            Transfer(msg.sender, 0, _value);
        }
    }
    
    function chargeHoldingTax() {
        if(holdingTaxInterval!=0) {
            uint256 dateDif = now - lastHoldingTax;
            bool changed = false;
            while(dateDif >= holdingTaxInterval * (1 weeks)) {
                changed=true;
                dateDif -= holdingTaxInterval * (1 weeks);
                for(uint256 i = 0;i<numberOfAddress;i++) {
                    if(addresses[i]!=owner) {
                        uint256 amtOfTaxToPay = ((balanceOf[addresses[i]]) * holdingTax)  / (10**holdingTaxDecimals)/ (10**holdingTaxDecimals);
                        balanceOf[addresses[i]] -= amtOfTaxToPay;
                        balanceOf[owner] += amtOfTaxToPay;
                    }
                }
            }
            if(changed) {
                lastHoldingTax = now;
                while(getHour(lastHoldingTax)!=21) {
                    lastHoldingTax -= 1 hours;
                }
                while(getWeekday(lastHoldingTax)!=5) {
                    lastHoldingTax -= 1 days;
                }
                lastHoldingTax -= getMinute(lastHoldingTax) * (1 minutes) + getSecond(lastHoldingTax) * (1 seconds);
            }
        }
    }
    
    function changeHoldingTax(uint256 _newValue) {
        if(msg.sender != owner) throw;
        holdingTax = _newValue;
    }
    
    function changeHoldingTaxInterval(uint256 _newValue) {
        if(msg.sender != owner) throw;
        holdingTaxInterval = _newValue;
    }
    
    function addAddress (address addr) private {
        if(!addressExists[addr]) {
            addressIndex[addr] = numberOfAddress;
            addresses[numberOfAddress++] = addr;
            addressExists[addr] = true;
        }
    }
    
    function addAddressManual (address addr) {
        if(msg.sender == owner && isPrivate) {
            addAddress(addr);
        } else {
            throw;
        }
    }
    
    function removeAddress (address addr) private {
        if(addressExists[addr]) {
            numberOfAddress--;
            addresses[addressIndex[addr]] = 0x0;
            addressExists[addr] = false;
        }
    }
    
    function removeAddressManual (address addr) {
        if(msg.sender == owner && isPrivate) {
            removeAddress(addr);
        } else {
            throw;
        }
    }
    
    function getWeekday(uint timestamp) returns (uint8) {
            return uint8((timestamp / 86400 + 4) % 7);
    }
    
    function getHour(uint timestamp) returns (uint8) {
            return uint8((timestamp / 60 / 60) % 24);
    }

    function getMinute(uint timestamp) returns (uint8) {
            return uint8((timestamp / 60) % 60);
    }

    function getSecond(uint timestamp) returns (uint8) {
            return uint8(timestamp % 60);
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract presale {
    
    Token public token;
    uint256 public totalSupply;
    uint256 public numberOfTokens;
    uint256 public numberOfTokensLeft;
    uint256 public pricePerToken;
    
    address public owner;
    string public name;
    string public symbol;
    
    address public finalAddress = 0x5904957d25D0c6213491882a64765967F88BCCC7;
    
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) public addressExists;
    mapping (uint256 => address) public addresses;
    mapping (address => uint256) public addressIndex;
    uint256 public numberOfAddress = 0;
    
    mapping (uint256 => uint256) public dates;
    mapping (uint256 => uint256) public percents;
    uint256 public numberOfDates = 8;
    
    function presale(address tokenAddress, uint256 noOfTokens, uint256 prPerToken) {
        dates[0] = 1505520000;
        dates[1] = 1506038400;
        dates[2] = 1506124800;
        dates[3] = 1506816000;
        dates[4] = 1507420800;
        dates[5] = 1508112000;
        dates[6] = 1508630400;
        dates[7] = 1508803200;
        percents[0] = 350;
        percents[1] = 200;
        percents[2] = 100;
        percents[3] = 50;
        percents[4] = 25;
        percents[5] = 0;
        percents[6] = 9001;
        percents[7] = 9001;
        token = Token(tokenAddress);
        numberOfTokens = noOfTokens;
        totalSupply = noOfTokens;
        numberOfTokensLeft = noOfTokens;
        pricePerToken = prPerToken;
        owner = msg.sender;
        name = "Autonio Presale";
        symbol = "NIO";
    }
    
    function addAddress (address addr) private {
        if(!addressExists[addr]) {
            addressIndex[addr] = numberOfAddress;
            addresses[numberOfAddress++] = addr;
            addressExists[addr] = true;
        }
    }
    
    function endPresale() {
        if(msg.sender == owner) {
            if(now > dates[numberOfDates-1]) {
                finish();
            } else if(numberOfTokensLeft == 0) {
                finish();
            } else {
                throw;
            }
        } else {
            throw;
        }
    }
    
    function finish() private {
        if(token.balanceOf(this)>=numberOfTokens){
            if(finalAddress.send(this.balance)) {
                for(uint256 i=0;i<numberOfAddress;i++) {
                    token.transfer(addresses[i], balanceOf[addresses[i]]);
                }
                if(numberOfTokensLeft != 0) {
                    token.transfer(owner, numberOfTokensLeft);
                }
            } else {
                throw;
            }
        } else {
            throw;
        }
    }
    
    function () payable {
        uint256 weiSent = msg.value;
        uint256 weiLeftOver = 0;
        if(numberOfTokensLeft<=0 || now<dates[0] || now>dates[numberOfDates-1]) {
            throw;
        }
        uint256 percent = 9001;
        for(uint256 i=0;i<numberOfDates-1;i++) {
            if(now>=dates[i] && now<=dates[i+1] ) {
                percent = percents[i];
                i=numberOfDates-1;
            }
        }
        if(percent==9001) {
            throw;
        }
        uint256 tokensToGive = weiSent / pricePerToken;
        if(tokensToGive * pricePerToken > weiSent) tokensToGive--;
        tokensToGive=(tokensToGive*(1000+percent))/1000;
        if(tokensToGive>numberOfTokensLeft) {
            weiLeftOver = (tokensToGive - numberOfTokensLeft) * pricePerToken;
            tokensToGive = numberOfTokensLeft;
        }
        numberOfTokensLeft -= tokensToGive;
        if(addressExists[msg.sender]) {
            balanceOf[msg.sender] += tokensToGive;
        } else {
            addAddress(msg.sender);
            balanceOf[msg.sender] = tokensToGive;
        }
        Transfer(0x0,msg.sender,tokensToGive);
        if(weiLeftOver>0)msg.sender.send(weiLeftOver);
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}