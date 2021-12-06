App = {
    web3Provider: null,
    contracts: {},
    names: new Array(),
    url: 'http://127.0.0.1:7545',
    admin: null,
    currentAccount: null,
    init: function (){
        console.log("Checkpoint 0")
        return App.initWeb3();
    },
    initWeb3: function () {
        if (typeof web3 !== 'undefined') {
            App.web3Provider = web3.currentProvider;
        } else {
            // If no injected web3 instance is detected, fallback to the TestRPC
            App.web3Provider = new Web3.providers.HttpProvider(App.url);
        }
        web3 = new Web3(App.web3Provider);
        ethereum.enable();
        // App.addAddress();
        return App.initContract();
    },
    initContract: function () {
        $.getJSON('exchangecur.json', function (data) {
            // Get the necessary contract artifact file and instantiate it with truffle-contract
            var curArtifact = data;
            App.contracts.exchange = TruffleContract(curArtifact);
            // Set the provider for our contract
            App.contracts.exchange.setProvider(App.web3Provider);
            App.currentAccount = web3.eth.coinbase;
            web3.eth.defaultAccount = web3.eth.accounts[0];
            App.getadmin();
            return App.bindEvents();
        });
    },
    bindEvents: function (){
        $(document).on('click','#register',App.handleregister)
        $(document).on('click','#unRegister',App.handleUnregister)
        $(document).on('click','#requestForToken',App.handletoken)
        $(document).on('click','#requestForCur',App.handlecurrency)
        $(document).on('click','#getStatus',App.getStatus)
        $(document).on('click','#Cancel-request',App.handlecancel)
        $(document).on('click','#refresh-request', App.populatemembers)
        $(document).on('click','#memAddressBut', App.populaterequest)
        $(document).on('click','#HandlememAddressBut', App.handleresponse)
        $(document).on('click','#seeCurrencyBut', App.handleseecurrency)
        $(document).on('click','#clean', App.clean)
        $(document).on('click','#cancel-request', App.cancelrequest)
    },
    getadmin: function (){
        App.contracts.exchange.deployed().then(function(instance) {
          return instance;
        }).then(function(result) {
            let string = "Current Address: " + App.currentAccount
            $("#addresses").html(string)
          })
    },
    clean: function (){
        App.contracts.exchange.deployed().then(function(instance) {
          return instance.clean();
        }).then(function(result) {
            if(result){
              alert("Data Cleaned!")
            }else{
              alert("Only admin can call this function!")
            }
          })
    },
    cancelrequest: function (){
        App.contracts.exchange.deployed().then(function(instance) {
          return instance.cancelRequest();
        }).then(function(result) {
            if(result){
              alert("Request Success!")
            }else{
              alert("Request Unsuccess!")
            }
          })
    },
    populatemembers: function (){
        var curinstance;
        App.contracts.exchange.deployed().then(function (instance){
            curinstance = instance;
            return curinstance.getMemRequested();
        }).then(function (result){
            var ele = "<h2> Members Requested: </h2><br>";
            for (let i = 0; i<result.length;i++){
              ele += "<p> Requested Member " + (i+1) + ": "
              ele += " " + result[i] + "</p>"
            }
            console.log(result)
            let parent = document.getElementById("requests")
            parent.innerHTML = ele
            // jQuery('#requests').append(ele);
        })
    },
    populaterequest: function (){
        var curinstance;
        var address;
        App.contracts.exchange.deployed().then(function (instance){
            curinstance = instance;
            address = String(document.getElementById('memAddress').value)
            return curinstance.getDetailByMem(address);
        }).then(function (result){
            var ele = "<h2>Member " + address + " Request Details:</h2>";
            ele += "<br><div>"
            ele += "<h5>"+ "Currency: " + result[0]+ ";</h5>";
            if (result[5]){
              ele += "<h5>" + "From Amount of Token: "+result[1]["c"] + ";</h5>";
              ele += "<h5>" + "To Amount of Currency: "+result[2]["c"] + ";</h5>";
            }else{
              ele += "<h5>" + "From Amount of Currency: "+result[1]["c"] + ";</h5>";
              ele += "<h5>" + "To Amount of Token: "+result[2]["c"] + ";</h5>";
            }
            console.log(result)
            let parent = document.getElementById("requests")
            parent.innerHTML = ele
        })
    },
    handleresponse: function () {
      var curinstance;
      var address;
      App.contracts.exchange.deployed().then(function (instance){
          curinstance = instance;
          address = String(document.getElementById('memAddress').value)
          return curinstance.approveRequest(address);
      }).then(function (result){
        console.log(result)
          if(result){
            alert("Approved!")
          }else{
            alert("Not Approved!")
          }
      })
    },
    handletoken: function () {
        var curinstance;
        App.contracts.exchange.deployed().then(function (instance){
            curinstance = instance;
            var fromAMT = parseInt($('#CurtoTok').val());
            var toAMT = parseInt($('#amountToken').val());
            var currency = String(document.getElementById('kindofCur1').value)
            console.log(currency);
            console.log(fromAMT);
            console.log(toAMT);
            return curinstance.requestforToken(currency,fromAMT,toAMT)
        }).then(function (result,err){
            if(result){
              alert("Request Successful");
            }else{
              alert("Request Unsuccessful");
            }
        })
    },
    handlecurrency: function (){
        var curinstance;
        var fromAMT = parseInt($('#TOKtoCur').val());
        var toAMT = parseInt($('#amountCur').val());
        var currency = String(document.getElementById('kindofCur').value)
        console.log(currency);
        console.log(fromAMT);
        console.log(toAMT);
        App.contracts.exchange.deployed().then(function (instance){
            curinstance = instance;
            return curinstance.requestforCur(currency,fromAMT,toAMT)
        }).then(function (result,err){
            if(result){
              alert("Request Success");
            }else{
              alert("Request Unsuccessful");
            }
        })
    },
    handlecancel: function () {
      var curinstance;
      App.contracts.exchange.deployed().then(function (instance){
          curinstance = instance;
          return curinstance.unRegister();
      }).then(function (result,err){
          if(result){
            alert("Cancel Success");
          }else{
            alert("Cancel Unsuccessful");
          }
      })
    },
    addAddress: function () {
        new Web3(new Web3.providers.HttpProvider(App.url)).eth.getAccounts((err, accounts) => {
            web3.eth.defaultAccount=web3.eth.accounts[0]
            jQuery.each(accounts,function(i){
                if(web3.eth.coinbase != accounts[i]){
                    var optionElement = '<option value="'+accounts[i]+'">'+accounts[i]+'</option';
                    jQuery('#enter_address').append(optionElement);
                }
            });
        });
    },

    getStatus: function (){
        var curinstance;
        App.contracts.exchange.deployed().then(function (instance){
            curinstance = instance;
            return curinstance.getStatus();
        }).then(function (result,err){
          console.log(result)
          var ele = "<h4>Status:</h4><br>";
          ele += "<div>"
          if (result[0]["c"]==1){
            ele += "<h5> You are a member!</h5>";
          }else{
            ele += "<h5> You are not a member!</h5>";
          }
          ele += "<h5> You have " + result[1]["c"] + " currencies!</h5></div>";
          console.log(result)
          let parent = document.getElementById("status")
          parent.innerHTML = ele
        })
    },
    handleseecurrency: function () {
      var curinstance;
      var index;
      App.contracts.exchange.deployed().then(function (instance){
          curinstance = instance;
          index = parseInt(document.getElementById('seeCurrency').value)
          return curinstance.getCurrency(index);
      }).then(function (result){
        var ele = "<h4>Status:</h4><br>";
        ele += "<div><h5>You have "+result[1]["c"]+ " in "+result[0]+"!</h5></div>"
        let parent = document.getElementById("status")
        parent.innerHTML = ele
      })
    },
    handleregister: function (){
        var curinstance;
        App.contracts.exchange.deployed().then(function (instance){
            curinstance = instance;
            return curinstance.register();
        }).then(function (result,err){
            if(result){
                if(parseInt(result.receipt.status) == 1)
                    alert( "registration done successfully")
                else
                    alert("registration not done successfully due to revert")
            } else {
                alert("registration failed")
            }
        })
    },
    handleUnregister: function (){
        var curinstance;
        App.contracts.exchange.deployed().then(function (instance){
            curinstance = instance;
            return curinstance.unRegister();
        }).then(function (result,err){
            if(result){
                if(parseInt(result.receipt.status) == 1)
                    alert( "Unregistration done successfully")
                else
                    alert("Unregistration not done successfully due to revert")
            } else {
                alert("Unregistration failed")
            }
        })
    }
}
$(function() {
  $(window).load(function() {
    App.init();
  });
});
