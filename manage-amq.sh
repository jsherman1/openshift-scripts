#!/bin/bash
#
# This script can be used to install/uninstall AMQ 7 on OCP 4 using the supplied 
# yaml files with the distribution. These yaml files are available from the CSP 
# on the AMQ 7 download page.
# 
# This script should be copied to the root directory of the example ymal files 
# (ie. amq-broker-operator-7.7.0-ocp-install-examples) containing the deploy directory.
#
# Usage: manage-amq.sh [create|delete] [namespace] [username] [password]
# 

manage(){
	
	usage="Usage: manage-amq.sh [create|delete] [namespace] [username] [password]"
	
	 if [[ $# -eq 0 ]] ; then
		   echo ""
		   echo "   No arguments provided. ${usage}"
		   echo ""
		   exit 1
	fi
	
	if [[ ${1} == "create" || ${1} == "delete" ]] ; then
	   operation=${1}
	else
	   echo ""
	   echo "  Valid operations are 'create' or 'delete'. ${usage}"
	   echo	"" 
	   exit 1	
	fi
	   
	namespace=${2}
	user=${3}
	password=${4}
	
	echo "${operation} amq artifacts in namespace: [${namespace}]"
	
	if [[ "$operation" == "create" ]] ; then
		if [[ "$namespace" == "" ]] ; then
			echo ""
			echo "   Namespace required when creating broker. ${usage}"
			echo ""
			exit 1
		fi
		
		if [[ "$user" == "" || "$password" == "" ]] ; then
			echo ""
			echo "   Username and password are required when creating broker. ${usage}"
			echo ""
			exit 1
		fi
        oc new-project ${namespace}
        oc adm policy add-role-to-user admin developer -n ${namespace}
        oc create secret docker-registry imagestreamsecret   --docker-server=registry.redhat.io   --docker-username=${user}   --docker-password=${password}   --docker-email=EMAIL_ADDRESS
        oc secrets link default imagestreamsecret --for=pull
        oc secrets link deployer imagestreamsecret --for=pull
        oc secrets link builder imagestreamsecret --for=pull
	    manageServiceAccount ${operation}
        oc secrets link amq-broker-operator imagestreamsecret --for=pull	
    fi
	
	if [[ "$operation" == "delete" ]] ; then
		if [[ "$namespace" == "" ]] ; then
			echo ""
			echo "   Namespace required when deleting broker: ${usage}"
			echo ""
			exit 1
		fi
        oc project ${namespace}
		manageServiceAccount ${operation}
    fi
	
    oc ${operation} -f deploy/role.yaml
    oc ${operation} -f deploy/role_binding.yaml
    oc ${operation} -f deploy/crds/broker_activemqartemis_crd.yaml
    oc ${operation} -f deploy/crds/broker_activemqartemisaddress_crd.yaml
    oc ${operation} -f deploy/crds/broker_activemqartemisscaledown_crd.yaml
    oc ${operation} -f deploy/operator.yaml
    
	
	# the following operaton may throw an error on delete, looks like deleting the broker crds is also deleting the broker
	if [[ "$operation" == "create" ]] ; then
       oc ${operation} -f deploy/crs/broker_activemqartemis_cr.yaml
    fi

}

manageServiceAccount(){
   oc $1 -f deploy/service_account.yaml
}


manage $1 $2 $3 $4