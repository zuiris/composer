ME=`basename "$0"`
if [ "${ME}" = "install-hlfv1-unstable.sh" ]; then
  echo "Please re-run as >   cat install-hlfv1-unstable.sh | bash"
  exit 1
fi
(cat > composer.sh; chmod +x composer.sh; exec bash composer.sh)
#!/bin/bash
set -e

# Docker stop function
function stop()
{
P1=$(docker ps -q)
if [ "${P1}" != "" ]; then
  echo "Killing all running containers"  &2> /dev/null
  docker kill ${P1}
fi

P2=$(docker ps -aq)
if [ "${P2}" != "" ]; then
  echo "Removing all containers"  &2> /dev/null
  docker rm ${P2} -f
fi
}

if [ "$1" == "stop" ]; then
 echo "Stopping all Docker containers" >&2
 stop
 exit 0
fi

# Get the current directory.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the full path to this script.
SOURCE="${DIR}/composer.sh"

# Create a work directory for extracting files into.
WORKDIR="$(pwd)/composer-data-unstable"
rm -rf "${WORKDIR}" && mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

# Find the PAYLOAD: marker in this script.
PAYLOAD_LINE=$(grep -a -n '^PAYLOAD:$' "${SOURCE}" | cut -d ':' -f 1)
echo PAYLOAD_LINE=${PAYLOAD_LINE}

# Find and extract the payload in this script.
PAYLOAD_START=$((PAYLOAD_LINE + 1))
echo PAYLOAD_START=${PAYLOAD_START}
tail -n +${PAYLOAD_START} "${SOURCE}" | tar -xzf -

# stop all the docker containers
stop



# run the fabric-dev-scripts to get a running fabric
export FABRIC_VERSION=hlfv11
./fabric-dev-servers/downloadFabric.sh
./fabric-dev-servers/startFabric.sh

# pull and tage the correct image for the installer
docker pull hyperledger/composer-playground:unstable
docker tag hyperledger/composer-playground:unstable hyperledger/composer-playground:latest

# Start all composer
docker-compose -p composer -f docker-compose-playground.yml up -d

# manually create the card store
docker exec composer mkdir /home/composer/.composer

# build the card store locally first
rm -fr /tmp/onelinecard
mkdir /tmp/onelinecard
mkdir /tmp/onelinecard/cards
mkdir /tmp/onelinecard/client-data
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/client-data/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials

# copy the various material into the local card store
cd fabric-dev-servers/fabric-scripts/hlfv11/composer
cp creds/* /tmp/onelinecard/client-data/PeerAdmin@hlfv1
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/certificate
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/114aab0e76bf0c78308f89efc4b8c9423e31568da0c340ca187a9b17aa9a4457_sk /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/privateKey
echo '{"version":1,"userName":"PeerAdmin","roles":["PeerAdmin", "ChannelAdmin"]}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/metadata.json
echo '{
    "type": "hlfv1",
    "name": "hlfv1",
    "orderers": [
       { "url" : "grpc://orderer.example.com:7050" }
    ],
    "ca": { "url": "http://ca.org1.example.com:7054",
            "name": "ca.org1.example.com"
    },
    "peers": [
        {
            "requestURL": "grpc://peer0.org1.example.com:7051",
            "eventURL": "grpc://peer0.org1.example.com:7053"
        }
    ],
    "channel": "composerchannel",
    "mspID": "Org1MSP",
    "timeout": 300
}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/connection.json

# transfer the local card store into the container
cd /tmp/onelinecard
tar -cv * | docker exec -i composer tar x -C /home/composer/.composer
rm -fr /tmp/onelinecard

cd "${WORKDIR}"

# Wait for playground to start
sleep 5

# Kill and remove any running Docker containers.
##docker-compose -p composer kill
##docker-compose -p composer down --remove-orphans

# Kill any other Docker containers.
##docker ps -aq | xargs docker rm -f

# Open the playground in a web browser.
case "$(uname)" in
"Darwin") open http://localhost:8080
          ;;
"Linux")  if [ -n "$BROWSER" ] ; then
	       	        $BROWSER http://localhost:8080
	        elif    which xdg-open > /dev/null ; then
	                xdg-open http://localhost:8080
          elif  	which gnome-open > /dev/null ; then
	                gnome-open http://localhost:8080
          #elif other types blah blah
	        else
    	            echo "Could not detect web browser to use - please launch Composer Playground URL using your chosen browser ie: <browser executable name> http://localhost:8080 or set your BROWSER variable to the browser launcher in your PATH"
	        fi
          ;;
*)        echo "Playground not launched - this OS is currently not supported "
          ;;
esac

echo
echo "--------------------------------------------------------------------------------------"
echo "Hyperledger Fabric and Hyperledger Composer installed, and Composer Playground launched"
echo "Please use 'composer.sh' to re-start, and 'composer.sh stop' to shutdown all the Fabric and Composer docker images"

# Exit; this is required as the payload immediately follows.
exit 0
PAYLOAD:
� �7Z �=KlIv�lv��A�'3�X��R��dw�'ң��I�L��(ydǫivɖ�������^�%�I	0� � �9�l� 2��r�%A�yU�$�eɶ,g`0f���{�^�_}�G5�lG�k��X�<hۦg��AW�t>���J%�o<-��_Z�B��d�O���%^H���%ğ���qe�K�-j��p��C�!��4��x��lj
v����v��_�+k������Vڨu�6�u�u����T��Z��:%Bt}�_��뜁ݞi�V�dOw ��6d}�m��=�{Ӳ�&��ܴ5%����|Іع� 6��>�����?�����%�<wNf����g�?��J�N�h��O�<�q�̿ ēb\S������_DY�(�ԌXSv:�cz��Qx�RT��j6���4'm��mmn���G��gat3��]CVO��؞n�*�A_8n�P���nѰ�H3`BtE"��[Z�t��x� �	R}�r�����b�V͞!�z�f���N�Z���	�O�Ӑ'�� ���BJ���ED�<Cq!)DnGvс�(*�q�<�P����f��I�Í:9�iݸ�=帪��tC�*�,E���zD�*�����a��Ai@j�����@��&N�8�0B��OQ6fx�NREF��I1s-����� u�D�u2�!������"D����Hqu$@3(5�%;HvP����Yu̴���Ng��{��8�0C�j�t���cG戙��}0�>N��������9�*@��1�A���@���������.i%ފ�u8z]��<ͥ��	���b0\u+���Xv0r���:��A�E'�S�أ�r�*'����qؗ:F%_�aB,|��gd�|��B̻L�!�Da�uB�nRs��P�����;c�)�#@&�;�;P� �5ׯǎ�p�i�y�|[ˌ�?��s[����8���a8��Q�?��#��)3�<��D���8����D*���_�����'�!�M���eg�bk��Z�����H6f�:,�!�]��&��<�&�i@�c��e7륭��|�Tm�|�	�����~bW�ח���]',�\9rI���{;��Vi�r��l�5�9� ��voC��x]B����0����5��������qF���4�̒��q~�R���(���ۍ��� �Ż�D7��:7�a����dc i��W����<��t�T ��G���L�+?BK6F��ъ��'��E��edx�&����k���"��%29e��� ��:�$�=�h'�V 	Oj��Kw�oG ���-Y9�EEt�1�s�A��'����O�ϧ!L&x���3��P��Ʌ�{gQ��2�o�v�����Q>*�Z�̨��u�C�@[�Ј�ғ�Y�P��4����s��"˳��Oز�C�%����i���]#�j�Rgv��+�۬ʳuR�q]���b���Q���fR���;Q��?��d��6X` �Ɵ�)�.��l:8"Fy�t�=�Vh{�X
r��M�@�Ț1�qLݣ{�������mz��Fd[�h�ء�tE"䧥�E���H��xP ����bC�p '�$�~�f�Rii�I�&���`~���T˰�B�{�vx�oVy���]�ǅ����2_���e���i����K�*�����"�����2��C�]�ؖԮf�!x5Gp6���Y��S��?>��S���v���Э�&YR��8���Tz��~��1���ު�����F1�f���U�ec�TԲ�.:�B2�#�����ٱ͝�y��?�a��4^��w�O%���/��>��Kx58����ϧ�BJL���������
o�2�`���O��Hө��υ����Erk��َ��m��mdٚ��b�]�P�(G�`#����o�DO�vf>Ж,�NizQ��"D���u�dW%�Êd��B�f}������r�	����$�5U|{�/w-}[��,��Ue��{���N����!	�#���"m��x^5��v�S �9"�֭��qa�x�Z��n��c,Z��I_�##C �u���ŝ��f�8�oa���\Xp:Z�����̢��������VVP��^!F��=8_,`�\^��K�ɳ1'���+�{4�t?M�>F�N�D����b}o�t��2:�����w[A��V�����=�x�$�ȿhEZ�͔1R`����`�B��'k'����fP�3[�\��n��>�#��y����^�D�mB�]��Կp��[!ah�M�gȿlB�1�1L��n���(֓��i��Ԭ#�9�;�cY�0ࣦ���Y69��Cx	�"&xX��"% �M�IE��ˤ�^031�*S��FKk���u���{�f���?0���(���o֋{�"�Ay��߬��֪Rc}�]Ǌ���4]ݝ�D �g�>a7Ҝz�J��-�Wv�tWث�l�ɵ|�cn��7����[ZΜ��­����~�G^M&��O<!&���E�W���<���b9B�哄ET��7�\�Mѓ(7��$r{��4��t���瘥a:"D�(O^@=�p�~��R�l�LG?��M�S:jsf�7����Fʙ��(/~qg��!����(��?�'��?Q^|��Ypt ��AϿ�+����_")��\H�%�il��qQ)W��l+�$�uR�:�z�F�E쫅�"�٭�HI����4Fh|��H$�-�s������"���Z��L1=[���Z�A]y����ku ��Ơʱ�B�W)*�A�lC
Ⓑ���5_�ۘ��m��y�����0�dq~��F_LBȯ�N�}�I}��琜	�M�-ڑ�6�&�؇���pԚX�v5�;�e���8�S(�����a��*4;����#0ɲtM��f�&����F_�Roa�%��$#ot�K/�k*ni�����򛁎��4j����m����轍i'��miF@�}��U�3�38�Am���*oU��'CA�Q�J.r:������Ƞ<�>>�Z��1y5=w��s��m!�Ee��֘�ٜ_�a��ן �����2'�d9l�cz|f����K^A���E�f�y���ϟ�`+��"u��Hq<0��T� � 
���ل{�qM����C�����L��CE� ,׌0��9�|���-� C�g �1���������	�-�*,W͒�,����\,�un<�����6�Ŀ��D���Y�-x�����ó���:��)��tL�������Y�M泉T-��8��͏1��t�WKڨ�E�-<����>*��o��CY��m����a��Ox�EbD�G����2���8pߝ�A��fOؘ�
8U�mY�擯1���fe�N�5TR41br	���[>���pd�ʹ)�I�QOˈA�齟q��z�˔F�|��@�W���lP�g5�b���;>��W�CY���#y��	����-3Lw��r�@S`��@@mIUm�88`	��'���dt��u�鹌_�kz$��Ӂ���K����S�cF�I�R<���Lb�Ҏ0ɳ��l��A����w�(6jT؉�9�1Q�>*���f�w����� Z�]
�Y�{��侏�G&�AjR��D�)���!3Y��m(��i��m4��@�뱭�:K�8f,:vq>	���,�r.�]�f_6`�b�5�;HV#�pυ�����j #��)�����	��@2�6�6��h�c�$m�� v�P���	���9T�)j���4�cd��r����m�R5K�:ӝ�M���ܴ ���%�l�ψcO����h�"x�a`"��9M�_P����<ާ�8����0g�����L�ܝ�Tı�	r p^L8�ѵY+��5����q�/j��e���~�B����dZ���K����)�����q���s��+��g����ÿ:u��8��DB�,�A��l%��L&�jfĄ��qB��T"������$3��^N���d2�G�p?y��F�B�ɽ�����Y˄.]]��.O��Яs��?W��r�'�'�|q���1�p�{��N���B�r�[!n��wa��	`�� 7�����2 -�*�0uL�`��!�����x�3��+ؿ���}���8e�?��?E�� s�������ש��e�O��[�[�ߤ���;�V�������w��ſ��P���������^_�3�+�#���b��~|7��/�U,�r"��Si,$�x"�T�B��)�	�#�P2b'�UA�-y9#�qx W����;?����'����/�~��_�{�_%���X�?����C��!�^`c:���~��,���?��w�����|��Vy����C_��������&�x7BJ��V��|��(���R�Hk�r������^)'�K�½�fgyy����ˬ㤳�����\���s��Y��
�~�\sz\��[ة�֊�{;�G�FI�v1�+o��UG~��P�&��F�A9W�m�~��-�z����� �/V�o�s
��)ך�{Fy+��UWY������f���s&����ƮX��ـ^���ʑ$��w���Z���P�������z��?���ڕ���ې��F�^���JŞU�}зv3�fW�뻽U���{B��h׍{�f�b)b�\?��(�F����+��ݝ����\��vŌ[��zkm
S������Vr6��A���]�0�����T�-����jm���D!��+,8�JG���z�I'v?�&�^�ɮ�lGn�S�.X��cWZݼW{P_�u��:G����-�I��շS ��ȕVy���u�*��c9	澽�-K�d�{ ������V�R�У��ݓz�\�H��p�k�b�]k�ɮ�$���[���I�{x/�똉�a���9��k�:֓D/���Z�ʺTj��~L��ws�r�]v�~fYO���o��[m+�wT��{�q�k�Kk���v2%>��v�Қ�,Z�Tc���%7�\�U^�q�b5�b�p�\�r�5�kR�Ck�Ko�ة�������,����6=��rT�ϕ�f!�r~g��/Iu���F���i��]�wO~P��K۬Miv�M˭qJw�F?�?���Gq,=�F�Q�;;;bv5��h3)
����/VZal���`�feۘo�����:w����2׹̿���O\UP5EuWwu���:OK]����<��s�����N2���	S���� n����q�� ���jk_���"����������T�M������4M��c�c��d�9'e��tb�;��r���:~ec�"ه�=7�TN���J2T�aQ���ǉXc��M���tT��S�.[Z���5&cJAV�T�ڼ1�������v��W����J��2*�Aˑ:l��!� ��M�k�,!Ai��/~��m[V�� m�c��ȎYV士$'�D�����{Cs2�@�vc��g����\�n6�_��S�a��]�o��t<��*vxY牨�S/+��{D�>0������L2�s��t�-?�90�:��i�~��.ĥ-ʉ���u�Z�F�=O0�v�u����1���/����L�')��(�����9�۞��n|@)M �6?�_�,��s�ܩ�P��4��O�҃j�������i���Ԏ/ ��G�������Oo�Z�f��%Z��;k����!=�̎;�O�Uy�X5l2t�X��=�WZ2ET;61h'�!��Ql�L�O����:şw	?�`��e�eĆ���m�&M�Z�fǇu�L%�H_%�?��%�&
m�*Cy� 2iF\GH��0��c���^f{��
S�6�<Qjֻ!�t�k�_�����m���o�eg����ߖ��h	�+�(}y�����^�"uo7��|r������o|�+��O�on:\e8}kkqt���ߗ�:z�����;��<�f&��K�{⇿:�w����^�(}~��_>rY�߾K��ա�?W��_C��s���?n��[��oK�������>Je�Ñʆ�m̗�ʶiF!�⬽&��5�݋�o�:�W�8�|���ݤzM,���i��b.�)�Y=�sAOQ�w���.=��J���S�Ή��)��U(P*Q,�5���	2w8T�K4�eu<�����j��P<���e˫�u��Z�����5g���k�p��a}�R,?s<7ZJI�lT�CoVU�P^*�ZI���6�Y�r�²�?1��؜	���1+���z�3ٔLk��_}�B���َx��!��2�-�tlK�Ց�v{�_5#����[�~(��
�Ȇl����VOrPsԙͺ(bz=����G ���l�I\�(B�iN�H�>
���7"�^y��7,y��+�S^�ez4y����4|*���P��
,˝��n��hF�f�>\�������O�q_ Wl�$���6:�G�ܫ8�'�"�
��6��0�k���|}L8K�c�q���S����CW��o��Q�U'�5���ۅp讅<(�a<��Ъ��m`O[�֗"s�u�>��ր�+�;K�:T'q���l��Gs���;���x4�2�+MS���*�\e�Z(�*�&���2�x=�l`�v*��!��nL�M��F���өn a\g%w^RԋPm�`[�G�jo�n���A�Sj�����b�[�p_Nf�j���]�m;L �DE�I�����H��;�'�h0#t� (���N.*�A��;i��z�OhfH���Dն3}9��FE�1ٸz�JG�6�,��	$��I?N����RrL�����	t���L�;�v*�O��y(�2��N׭��rDM�����Ԛ��Z���R�#ַ��v�r�����D�)�}&���jԴ�YtG>=T6��F�4�<5�@���@@�;����˜���C��<�e�t�<���+���M�5��
���Q�ЀPH��mPrص؁��z̮�ng1�H]����ls���#{�$*G�b��DX �{s0p-�h
Ӧ���t֥��.������]�u髻��|v֍o~+������k��-���x^MG��_���t4כG�(]@S���%�E���|��_����~S������?~>���Ww׼��.}}�����#�+.�����px=��>�@o9�����s�;蛚�[V��`q�C�Y*���<����]݇`���F��\%�݋�;�W��e蛛�9/F*����o_��^$�O����?�����~���m^��������,����Z�{���폣�������.(��)�ch�L�
~�����p��E�;�?����O%�]Hw���Ͼo|������X�o:��������VM޷	�d��O�:��	���G!�����?�����@F�]��.��������%���	r����e�7 �����!�?
�?�����z����������`�''��]��b�?�_-��dH�Ȋ��P�%(����� �m�����.iy���B�?���Y W���� �
�����+��� 㿙� ��<����z��8� � �Yg���sF!��^��,�����X�/������O��������W�*��Q�������������m=��V�=�à���ܐ���ӣ���	�����+������`@>(���������0��|Q���@��\����G�b�������������A�ߌP�w)E=ĩ�C�v����3�G��=��
�yt�C]�r}�a��3$�!̑3(�"�}��"�?N]�������V[�m��u���R�D�M�s���؀�u�y�A��ٛ|ZW5�&��:F3���\}��-�T�Q�M��Mu�75�+�N+s�N%���khwi�7TdSm[�)騖�
�bL�sN���|�Z�A���r�i2DX*�߻���?����������x
&}�"����C��������+�:���?�g�"�?���C�?�TL�T�-̂{%t��0���-��&Oo��x�����Is�5���q׋6���fhϜ�(����u�S�Rݮ6�V�]xU�;C���xK��j�Xs{�M�u 7��>��<�o�B�� �9!���گ������|P��_ �+7��/���@���/����C!�I]�?�/<Z��J�5o�_S�uu�헻�$r|r��������-
\�H�ҙp�t 7�?��mc���E��I!�� �oF5ca�Nw�t�2]ᰝU���U^���Cy�d��l!�f�:b���:��K���P��u��cG�V*K\�����iSV���������)Xs�X�tW�JSH��wji��4����(����Ū�l���+��;�O>j�*�,�Z�Z�QT�ܪ���&��z��f3��&�7��+��Cr��/GQ�f��E롡V:�����QT�t%�n�v6��>y�wE�(�����2�G��`��B#��l�yh��d�B�?� ���/� �E^������y`�W�Ȕ�A���!+���_��o6 ����_���`��\�?uQ����2�`����������zQ����Y�?��X(��`�?����������������?��Ka����E����C���y)
����� �?��_��/`���"�?���兏�oN ο�Ȣ����qP�7������P��?d��7������; ��ϛ�1��_
�ȗ�Aq��������rC��2C������?q��/X����� -$d���Z��?eP�� �@��|���������(@nHn ��y�B�?	���B����3�0�GF!�����1<��!����������(f�p.U���j��I��j����H��<��ug��;��Oi*o��n~9�T�Ѫ�l�k�5��ب^�ۅ)z�(���i���װ�ءqË`H���
*�~��xwcnuWé���w��H�K�>J�@�'J�@ޔ�Nؤ}t�V}Z1��Q��
�x8�$j�@�ݍ��1۹�EG�e����&�{hH�[[n�]x�D��PT��{��%�h�l��;��}`����	���8d� ��y�B�?y��/��!#��Aq��Q��@�G��L �?�����#���?���?P2O ����_!����P(��!3G!�?�����#���?>_B���9!�7��Q�X{��������+���e�G� ��
��CЮ�ӾOٮ�Tlo�#擈CJb>�!�#Q�Gl�}����
�)������(��ԥ�������o����}_�'�/��@dUN���J2T�9�.����D�q���؀�&=����W�F��PWB&����6�ޠ�T�I���Ly�f��js_�/z\�ew���uh������&����n��v;T�C%���C����NC�����k�Z(ʾ����w��.n*��`(B��?�C��?��I�|Q���_~(����!��~�WG��g�Q��/?|H���6Sk4�:-I��!	����1���W5L��K.	c}u�����U�\a��R �͜��|�6�	-�!v��wi����p����^*^ܔ���hnM�r?K�����	���E1��E��&A�����~�?ŏ�g�B���_����/��������� ����H�/'<���T����k��%eͷ-���؊;+d~���g��nj ~H�����)�n@yD{*R�ʶ�2�˲�'�f��q'���e4�(�h��xP��=E��9��M��t�i7��2R�Z��U���ynr��̃R���lR�otwu�r=��?{�֜(���{��U#��Ůڀ�� x���gTT�_�5vzz�t��|0��L�T�!IG�_ֻ�u�$����,T���Ri�/�b��B&��f��W�{/���.���Ksj_�E�Q-	/����I��)rݽ��Y���2�1�'���c�?�E��� �$�R�,���h��Q#����t=g;�'����R7�K=��]����]���N�#1:*Ɛ�LCC�3;�&�CP������Q����/��p���:������H@��fz�T����_,AA������`�����/�}��	؈���	�Jy���F��W�$i2��_?]��'2 	��
�4v}u���� �Cį��kk�j���f��w���L���8�N��[e/RD��ʑ6�V���Ö[Ԃ}4l����R��?����p<�Q����4����
�����?GC�	u��y�����?
�?ަxTr)O�d �TDחi6R�&q�Mӈ�)!(.d#&P ���,�'Q���ŀ�C¯�-6KE����,\�8���n2��`~H:���3z�S_J������?V+c)W�U+��{+�x��$�U��?l��)������bhx�� �������n��?��M�R�_������ѐ�C�����.#������OQ,�u����A�'"��?��Z�
<�����3�DB�������H@����~��C�R@�A�����_��	U��mL���W���r���_�Q������ߋ��?���ϼ����#�N���8��}2���o�?��?2	�_(�Y��=�e1Y=�٭N؛���/;��0��+�֋ʜ�t1����{������wQ\���n5N�d6�.���V�f�*#S��b'����AW�361�`l�Ë�Rt��i�Tgm��ET�)��ET
{|����0S3���H��0�{آl����N���N�f@�0+SNO�l�/|1,�ѬHla�;�Z�bQ4��9K����6��B�}�n'�� .{k�{�ͲX&{����#Gk,Blzi���ؖ�Du<�z!3��l�e+{����J�$�V���L�*��\�S���Ծ�F|.s�{�xy7��2Z�3;S��r�J��{����`���SNs�=��8?w'�E:�l�U�-��%Q���n�\z�4	���c'�_2�Ƭ뱻F���"�Z���=d�����ǰ�q4�����y�	Y�w�/v��I\�S����VV�����o��CB�b��!P���v�W�g������P/�|$>�:��d_�?��D����z�����Co=��)��|��re��_�E�_��������KQ����Ԑ�OZK�ט�BZS��zxa�M#�t�Қ���x��������k��k�h.��\�GS�s.�TFjJ�=MQ�����#F|���|���E\%��'�&��i��ü{��lb��̞mM���v$m�]������I`�F;��cr>�o�o8�0����rV�Ҙ���5EZŞڵ�n�V�Z���Wq.��m���:���l��������tI�vNwQ��f5H"=��v��f��a4:��������L4O�m�.��d%ۆ�$���"0#�9]���3�`=�ʡp��f�g�`��9�y;W6������xhj� ��eZ����9�����j�������:�O� P	���v�W�g�a�'j���91� @F�?C>8���oH����n�������q�� �/kY>�t�����?Y������d�nCT�[�?�����h�� `/¼��Z���g���3m�]�=����ָ�r�u��n�',j?����E�����sa���8�ɂ4�q����Hg�оS.c�?�d�)� el��u �s!�{� 8?ӆ,
4`��X�˸GKZ���R�lIM����C�� ��v������&Ċf2����*���(fg��wx�YȺ8�rⱵ���(j��X��z����x�
�E�ʫ#Ϯ��%yP���e�!�n�_	���v�W��_5�( @L�?��W����?����-�?�������u��ɹ���?z������O��?��GB��� ��`�'�x��Χ����@�TB��Q4�BHpA 4�p�%���A�����_�����ە�|�f�����8��8���ry\�[Itq{M��svG��=�٘���d�q�+y�7�$����;�sf�˄���2y:Z{y~p{dB��ly�s���x�J$s��2�{+ux��������_¡o������:j��0��2���o���V�n|=������W��~D�̩��e��66ؾ�MY��㋣^?�M�O���Q��7��&���0XZ�&�k��n7����в��Ǭ�&г�D�����MR�s��t�9�⶿5[�En�I�S�~hm���Ta,�o��
�Q����~�7�_@꿠��:�������� ��_���+��N>��C����,��=��W��R'R�Hޱ���.�G^���o���_��c�[hג|�W�M�xbo��Om��n�q�f�u\[�h�M��Acq+܎f�Vđ30����F,��Ȉ�̘�s�r�۔*,�<�f솾�N���T�{ۍ�o��m��ӭ�o���זJS��]�I�Җ�:q.��O�zd j�,�'�zJ��'.�]'�.�L�y���A��h�(^7D��ز�q���
-sz&�p<����yb�S�䧃�Ah�݅o�3Iw�1E��n��D�-��F,�d�m�1�H[j�L������}{��] ����X�ZcP�������?h��@B-��}��P��D��]k
�?���O4�E ��Z3P��{��Ұ�	������W��Z��U�	���@�������k�u��$���"��?�x������i��G��C�?��C�?���>1��/5��׎��������Ê�:Q��h��� �_`���W[�D�?�~���_������k����	��#��O������(@��p�_WP��{��)������������J�?����E�����e�0q�ǹ8�	2�#<� `YZH8�g��
��62�H2慄�"`��}u����?PP���_����E�x�d5�]cf!9��e�����k�tn3ɷ���7��?zn�k]���V㏍���+J�mf�r7��2�{��y��G/%_IY砙�G
��Nh���z8�j����R��?���O������� �	�����?�A�u��x�����L��������w����?H��?����?���6��@�_E ���X�60MpO9>&��Ax�%q	OD	��|JE�Q!G�I��	A�AG �B�����4�(����2m�g��l�/��A�b���n����	=kzTR$���<�v�v�ln��Q�bť�692k�J��~�c�s�#ޛ͉I8Ğ
.�S���ݠ3�ﲡ��.5yH�Br��<�4�-����:<�!�_��v	�����C�
��(�������?��d��?�*�������^���`���XY-������?�@�!���:�?l��������y���GD���CуJ�߽��?"�?���� �����?��$�!�+f솨��_;����3�k����H���?�� �G�����D�O�?�W�����H�XN�bʒ�a/g}��������_���}���:K4<��������}��y��LB��d�:��̶���:+}����]�KuX���3%��%=+	�"���V�)ݛH�p�Gu���e*œ�������'��wBȦ(�����%�.�\���Ǟ}�[m���[��=#������yg��뤕'��taN��dQ��Tu\��L�'�-g�IKҐ��1����VE���g�|hW�����Q������C���r�ߎ/�����B���_������?L�BL����O4�0�	�?��'���⿪���W�v|9��������2j��������:�8���������#���;�u譇V�7%����Y�,��KVF������駦<�'�":w�����ruu�`���sѻ,r[���f��E����./�?��8�_���*���r���i8�
��C?i-1�_c�
iM���ᅥ6�,ӍJk�����=W'G���O��ϯa���rMe`Ϲ�R�)�rd��}0b��Y
���n���뢤x�$ل�8\s�w��5�M�ќٳ�)6r܎����ѐ[:^:	�h�`6cL���M���f�wX�V�jVsו��H���÷�g��{�e-�|��)�)��sQ4����륽0eCԥ����K�s���Xm7�A�A����6k����Ap0����u�u��g��x�n�ta�,&+�6t'	��	���op-�I�W��73=0����9�۹�	�4�0��CS���,�w�-����F-�?�A�'�DB�Er.��.����_;����S������P+��Ӑ࢔!�g��ᙐ���0�:�C.��(�X*`�����"6b(�
�����p�?�$����ť���L���v�b�"/���"�6+QhP�R��������i��~~���N�Mx�l&���lۀ��9^�-�����Ød��}�$uӍ���_�.�9tK�R��T*���_��������v��l{x٫ݏ�����ɴ2vS��^����Ժ�|�:�Ts822��m�{PӪՓ�V�5e��'������:U����W-/a�_��|���뿣�}�������{��"��:�ǳ����E�q�>75���K�����������Z�=���4>
�N�=m���v���Ъ)���鹒�0�t��_�0�o�>V��V������=n|أ�o�a�?�hJ�ru�M^�큝i\�Փ���S}R��o��O�I~b+�OǵR� ���Ns��ߪ�e��������KX�W�����?P^B��������������������gm�=��gm>Cy�l�n�
k��)�2������,��5�:{�e��s�𪚪i��/7����g���VR���]�mG������w "A{v� 0U����r^Zh�F���; ��˾�m��o3s��4�ɋS�i��M�>Lꇻ�y�Sm�U�)鷃F��a��s���-�h�jU�&ۧ`�[����N�Idpz����4�C�<�|��p|�[��a?`���2����
�iZ�O-�ػ�X���R��+E�����f�Ӵٓ��2���G巕]���~�OOu�)n�4PJG��J��� y`���Ė�~����~�r�_ִ/�j�Ј���ׯ�c��yX���l;�:f�;�d�%��G��O�ףO[��U��J|�^t?|�^v������)���X���l:��ӹla����T����C���G���II�I�٤�8_��ȫ�+�iU?�5�6��Uf8Z_cV���T�X:��zP1�p�E���,ni�Q#U���b���?Ȉt�x���T���(�)FyX�Ov��c�AG�聐�9��Q$��?�b�3f
��c�%�G���nNHߴj�9���q��H�pT��#fߴ�G���3�7ޕ��Gaa����A�Q����q�����������+q��Ml�pqL���<f �c]S4D$�BC�_�h���%�uڵ8_�	9�:��n��j~B�+�.�Q���( H8|�0���E��!>�Kc6���0{6žmQ����$�T誔�WsGț6��jS7Iwȥ��Aa�wĦ 8|�Oz< �43�o�\eP}���h�����(h��ci*C��l[i���S$8uu睘-��؝%��{���u�	N����	d2Ԁ�fρ��?����.�o�#������	DH���X�#�]2}4�h����&<�FbR�)�ޢh`(������kCEorm��X���T���ȖCh�,D�G�[�{<��I���0�̉�Z.J!�B�����R |U,X�@��.}Tק g<��@����y�F��������x*�k8���v_L��L.K��`�JH��F���K4�\*5CeW�M�oJpr���8��+�&�rG�GQy���f<$�$�׍(QR"a�!#�q� �TݵA�@Wx��f�g:C	O�t�C��)�� a��q�ܛ�
4: �R����N4G^1u]��#qN7�㈘�"Iɯ �H�"��f"ڭe����c���jH6y<q:�u��dIҠ�P\[	U|g�3X���r	;C��n	#>ܹ	Z�����_5�f��wl���X���eS|��J���l���|:����')8���E�:�:A��=�y�ki#: �N��ҙ: ��,���F�]�m��'cc�]jL��̸�,�@�v���-����Y�t��<��$��$�����a���Xk�F	@,@:�[�M�	���`�"��mnP�EbIL!��{�,�*1��k`�/��;$�+���y����ڦ�|��z�dv+YP��J����۔�|>��
ɭ��О��4�N�[�,[`)���̾ �᩷���xBb�kN�KSwG,@���O}�(�:9��:��-S)w�7�r����K�W��7��Z8p�֨�K�g�ͽ������z���j�N��(U��Z���������;��Q��߬� �,��[?\ P��Ε��cf�>ˎ�tP�w�R:<����6�/KkW��(��oIh�́LL��3U��$a����Sg��-%1 K��q��9ga�5.�9�QO��'1�`���+T-,	��CPd;��� 7{������|1�/����������lא��ꍽ�E�+T�K�F�Y��Z��O��U?���V���vUL$�I\R+a��4<�v�Qy�V�X󎑇�zbwY�MR7p�6+�t���V�����Y����l��v<y:���NC24HhV	�
�Rw��� ¾��f�V݃��n�[��n�\��v�T����+͓�~�,�$�yR���+涷�*��W�_X�IL'+���؞�[D9�#���'���>��&�>W�L���2b��wn��_��[�p�+]ecf���>9o[K��TS�,^�e����6]4�Ș3�\���峓�!t�8@��rT�	�#���3����b����74'��s5]�;W+El-��%�����o��Y��>I:�@����N���(;�g�v�"���v���R���T�x���Ԛ|KS��#�=ap���:c�)�݉�l�Az'�ʐ�=P�.��WA��xK���*�^�'���g�?�|?X��2����ɥr"�#�^��S���g��Y������g��Y�������H�q7�N�������g��Y�{�]V��9�Z�91v�۸=\��e�
i~�+���f��?�]��z���o��f$z�b�~�
C"��,�!̲L�[����������1hReS0HLj�ɵX�y�.L������,���N�kY�
+�6�i<�vbt�QT����2��ְ��N�]�����:J6���_�x��'�� 
ؒîra���\��5���]������#~Mb}D) ������K��u.k���`g�ɿq��@m��C�$�$�y���H#oB/	J��I��&�b��5���#5�	QtF�յ���o;��d�2����3�O�A���Tf-�OQ�_��D�H�����Ч�@���k
��ht�����u�4�#+`����.#�P�3�l�2����$%(��ߗ�֟7��{��M�z��"ߡ,��Gl�����O�_���}��=�����@#ӂ�!7��t�t�:�Z�K%C����6��1��/\Ϙ�!���s�9�� o��w�P�i�v�x1`C��T�@M�n'A�	�8��DZԲ�Y�����m'C��A6^���!I��o�M�_
�e#���_�.Lo��_�k��zc�)"&��o��:H���p��Iz�j}G4ov���RQ�i�ڌ@�6���V�ݝ��T��$d !�Qr��Fl~�d���և����rg�Dz��)B�9�E���+ʏ�#8I Z2�B,���*�-�oG��"P���x*�C�,�ڤO�rM��⿎�< �"trAb�q��;@y��~��o�.��1�	����_I*D�F{]�^J��\������oȻ���Nh��dM�)��9b�^Nl�p1;_�5��ƛ���S�h6���1��,H3@%�:��H�<J��%� qCFP�������%���3���~��6��w�&�<-�(_Т��Cg:�����?�q'Q�ң���RL$�_����W9J�yſ$�B[��wD�E6�n�т��资ĝGAD����F-��c;'���BܼQ�`ƍ۫g�~��!�Sr�o���#��׫�^�7}k#f���$��`�@��Ĭg�/��u�����J����������Ja+���om����m)��t�eR���J�
#
Mm�v/U�t�f��}�<O���V�ed�Dg�
+��l�/F��L�br�F�mU�o`�l�e����: z�o�u�Ԯ6O�����9`q�k��V��BS��$6^,�$����s]����]�� �3+X�"2�D~��ڍ���Ck��J���,h�s:S����GՏ�	��7���<̐�2��0�|�/-'�M^K]�Z�kt;�s*�~���m+#��/�)���ڥ�#��?oZ[¤^m��������$����')?��� C�^RM�	0M��2}�A�˭eE����hZ&�����I'S�������:����q��0���?�c���M����)?���|���p����_��Gx?�����P !�l��Br��	�iw��*ɩl�	l����|���h���?���N���u�G5؏�ש�=�D��z�����[gl|�[�N�ҋ������]1�3�#��{3sa�&:MpG6�J@r��8��Gd?����%�x`��(��r�5s�v=�a��Xo~�2��U��R��T��%`i������������������'����	�>Z. ���Ё� U/P���I�N��?��˂`��������V�qy�����1N�M��U��_�~��V��g�*`����������-�+e����_������҅t*�����l&���OQ'�/&�z����O��<�o1R��}Ɨ�P�K����I�z`;��d��*�G�����6SV ���^���1M�}�q��EqSm�}�Y0�|^�_$�o�"��UD��NG�5T��V�.l84w4�Ŀ��W�	rI�~�2��ܥ��$�����Ƙ;����4��?L@����#2�a<|�3����2������T'M3�����S�C��o��4�}�,d&�*�1X}�̜ΠT�F	��c���qy���ȫ�{��bMWW���vfO$v��4.��+��sO�� �l�|�nBV �`��u�H�"���"��	�4�I�=J���'Ø��|���^2��$��;~�P�nD. �^EՅ;5�H�Ig\_�� �*R ���,/�-WM"�/�ȡ��J��$�;>0�H�ygN�z�r\�W�(��9S?{��� n�[�]Q�1Ջ�mģ�Q�֎�&u�z�Ӊ��'R\([B�"V&=�Z��Mσ�4���,`ؘ����x�
"(�3H<��e�6� �m̷��!�?���*s����8��!3��`y&��pyU�p?��0�����]9!h"��3g�������8�J��l�~`�Z#�L�D�����R�	�ǆME3�����V�$��t��vfp=�j#,%_��K�\(�c҅��H��!���J)�����dW����D"�m�f�;%��AE���B�UD�%U��m�/)��'��-Sx�+���t�Y^�ҁǈ'w?�X���6�JI�r8�$m��w�o�,ñLݞK�<��%�Kg���q���(������#z���Ѣ �Y#�oC�s�F�$4/	q2�[�tvam�n�S�,h�=��ok��˜�|�A���Y�aX��b񙊓]@ϲ��-rTb���&��Co�xp�H�{L�)��P�^��п�g�F�	�	�-����vF�\*M$EPN�����޵�8��������3�3�{n[�KS�]�dfb;�ăFߒ8��8q�Z9��8q�{�d4�y@H�0�-h^о�������V ļ x@+� �vn������ꎳ��Z�:>�����s���t۞yp/x�zͽ�E������ ��κZ	4�:��Q���x�����I�;zT���u���\c@ާ`
=a���+i��Į��dyY,I��r(G�g��Λ,&��>�B��4�����W��R~��x�lٱݘu�p��l{��y�G��{�^�������ߙ9���qY�7�����$���q��v������>�s�?�鏿x��yɷ?�#5X�0��64DC0Jm���(�Q�P%UCt����4�p�BjdGkQ�~�6��mp��}���! �=_z��� ���@o@������_ނ�{�у<�up��8GG���;BoA�|�ﹷ��ͭ��ܸ/?�&t׭��M�v������*X�y{��j��w�/q���H��q��?�O���' G�"�ψ��G��/����௉�����堿��O����W�+�=|��� `~��ֽ[.W�h�/y��������bD$��*�b�:I�:�����#�8�\��1�Bq���j�B���*�C�w~�ǟu����O��|�������|�������߅��a�a�� /mLC���7��`��}������y|A�g��}v����K�a���,rh\�Wn�,�w�ipe.Y�4��Bhd%���[���c�f����2G����6\'o�v�X��7�*2�r�(��/����t׹e�
ʏ��i=��SiN�b�2[2.���[6[�ɛ2 &�);���������~yk���Jiګv�Y�c5�\ŉыm	�A�0#g'�����Pi"��N�YTH�Sƽm���J	qj�¸�R#1�8qcQ��TjU���cm�w*�Ub��7Ɉ9Z�8٠yЖQ��0\����y*9c:�t�N��|9J�����Hj
�g-}D�2I��K��5М�b�$������"�T����I��tt�W�J01���EeeY���τ�to�"W�x����:���7�+t_�w@5�;�.FLd�ܝ�+v������ɗ��{�-�l�
[�ֈ���!����Z�<d�� d�0vX׸�<��/[Z'�I)_���'��d��� %�t�rC����)m������z�ƞ$����(�f�0�uˤ��ۖ|&��6�%�4G���<*5�MJ{e�&	�=b &�v���ʎ�N���*�4�t|MM���yE,v�R*��T����	J9%�$�t�T$�\�QQSt*��󦉋d���.*�Ia(ֳ9����Z�¤E��gpދ��^�&�
9��Π��IF`(0ȥ�N���u�&��� fc�h�I<����l�g��+�,6L�`y�_S*:U�^��M�"9��v���	[���SD�#%g�n���T^pD��A�(&�*l�X�"'u���/��̼^�'h���������9��6f���$G1�9BHR�r�=;kvP_��#)����x��&�x�b�rm�<�s=�u�	�g{�i�%�g~������y��p.N&Ǒ)��CUD��L�ZR
ZkfMbB�*%�v�VG��XN�f�fI �XAŪ9ǪS�� A�=��6p�������y�CV�t#����*��d^ΠCKdT�5w���i�}��'M'&�A���Q��t0���̐)pN̮�ʜ�Q2��mV��i��p��h�:Ϥ�&Q�2-�p�S�F��L�D����m�������K�&t �q�>x��%�{[������w�=�~����x���W+�]�5�u=����ˮoy����7ëz��LBxu��m8���}CЁ{-/B�]w��%�A��w��"�;oB���Jr���?Y��܇������^�_Je�Keu�����$�M&˔fO��D�������m~���k�Ϣ����Ė����u�s��f�5�k��Q�����%;���.gt���"SX3p�#�m�<�RRh�1�����!2�#�4-G�Q>!3s$� �K$C\/��Z2��,V���T�2X�U!�g�f��4۩�ڰwF�*F��Ҽ܉%S�%�]$ꀲBg�,]���YV+kF���t��{������B{d����]�s�l2,���y�d�a҅F<�C$9R�ݾ�@�W���-T�s:1����9��M�,�v��!J���X��$�.g\a�x-,;킣W�b-c���5�p���&f���N��Vk�h�Ã�@6�遣߼�Ӱ�P�m��\I��Б�q:�Gә�1n��g������k��>-�cs���\Gj��#��*+s
��Lj�3�k�$��	�2nS�[|z���u�������oѕ���/֮�����	�.�<��꣡Y�eGC���,Z���T�r�m�u)�K�\��y��a�ɥ�Q��u��:W}Y��v�d[�pU��|�/I"?<Ǆ�H;K��/�2+Ҵ�Zv��ʎХ�Rg*�]C�b�KL'����R��r}:Q3 ��B�`�I�λ��B��qJ+G�z�Zԓ�R[)�{|2ON���4����"���r��aN���D��f���tC�gΈ�SM���UX�F�s��'��ui��ϐ�N�(M:r�.��XD(&]o��*qj�nI׉�+C2�����;#Ɲ�1��Yp��/4&�뎭�IΓ�k��}��J>iG�BQK��А��Yd�U��Ԁ�����F	�N�r^0P~Rz�j�T�"�qf�F$�*��f<bͣ�	�����(�5(`mQ�1(d!]Q��#�����Hnh;����2j��T���bbB9ż� ʹ��2��%q�6#x�X��
].S�,=� �Bq��C��ɘ���8�i���#2�t$��*�0k�T�Z��g8+�_ԙ6�4r�K����t�+����m��эW�'r"����F�"��Ң9}8�ˬ������/���h�n�Cot�^��l��/o��@�C/�{>D�z���������k^�W��m�df�m��"QQ���r�&�@W�M�tVj�	�%�aӴ�2�Oڃen��]��}p�H]�_�8����\���.�{���,F�p����eH��E|y*��� 7�������ɾ�r�����؋�|���q���Du��9.Y��.����8��w'�h��hӢG�x��̺[���w4�Z���}/f�;Gj�aZ��R��ܭ��n���y�}?F�K����ȋd�Z��7c��[妁��S���}t�E�3�*�v.�"���A�G��ql�t�ؾ�4Ա}�y�c��Q�L�{7��:�o:ul�t2�ؾ�lԱ}�tԱ�Xw��>������0ݵ��i_���������?�FH�- #�/<H?��yk�t�&��l��(�i�o�����5�o=�;j�K���������o��I���)��(����J%��
�K�Ӓ1=i��l'rt3�jLl�6�U��b,G5�]�[�!�T�=٣�Mg$=4�)L%z��*G|p�d��̕���>?����Ȇ{�9.��n�'O��8N��N,���K�N��Ϗ���?��������̉��`?���y�_�'�����P�@!�p%}�aⰣz�P��t�Iu�0e�k�]P��E8��u)^����tm�K�6:n�Z����`�傔뉅�<��dh^�:���t�.����L��3<f�x��@��6Kv��+TGU�s��,�%X������x���~���k���BW:�����P�@����n�w������N���?�4h�]�Y��v<1�Wm��A���A�?{�������Ox���2���8�����1�������Y�G��v��˔9�ua ������0����/���� ������>����w?�_S�Ń�萟�?���?r��?���N����۱��
���{ �s�]�����	��cA�� �����=I�>�{���^�?������	��^H�`�_��������s��;�~����� ����?���� ��ND "�?����>c/���8��o�S���a��g�������1�������	�/~V�{��������Nd[
�-ٖ��m���t��/��}���O�J��W���������7�	� |�^�����o�����`����^�?���O�S����p�����������������{���"�עdW��!$Q�5(TǴ�ZoD����Q�0Bk4j��n�1�`2B����zu?����g���������/O��� ��������1�P�L/���ʡ&����Έ�*��"ڍ����d�BCL����:�`H�$V�'1x&rj��[xM,�Y#Ə�f�U;R�{�mD��LHe�s�����/ϻ�w�`������/�?��I�}�>��������A���'�/O������_����x���"�rY�.30p�Tȡ4}Pr$ð*��b��Qɯ��_lg�RFiwjڠ����N)+	��K��ĊDc����-�O5
������lo���d�V�h;>0�iv��C96��������`��'�i�5�=m�y|�?C؋�_��_�!��+��+��+��+�	��O�?��{��p����o�4��B�eN�_F2F�Xoht�\#T4�<�'�ϝ��U���;�D��1�8ҫ��S:���lۣm���wm݉*��<�+λcl�_� "*(*�^�(�.
���?�I�t�����՝5�c.��5g�\kі�ٛ��hZhu��i?�u7��'-=,I���a�J[)��	u.m�"�6�p�nШ�n�%�$rѾ"���-��_Ѷ�����-���UjSQ'OZ�����بjnPy*S�G��z��}��OZ�w+"����Q�o��zE��?��^K>��.�����Q�gg�ݭ�5��}�	-e7��Ue��ͣ69����)�*�Ji������Yז=����?�b�
L�jG�v�?^��g��5����_N��_< A�3�������\ ����,}7�Q�$������<������$�������0��?��Ż��0�p��0�\�������g���������s��.�{�������B���������@.��m�G���/���<"����������� �`���	��`�WQ�����	��	���q��������?D��`���� �?���ք���_4����_�
����`������p����P8�CeH� ��/���������b��B
.��X��f��'@��� ���C������?L(\���jC�����������A������ ����\�������J�Z��j�G};�4j�L��֦ܯ;q�z���ƿ������p���V��K��?ՀPϟ|��鶪N;��n vڐ�

ʢ���ǝ�յ-4r��ܗ�n��)+;ld�r�Gigjs�i���'歭��E7�����E ������SH'W��š��T1�e,�P��ih��:5�J��-M��rX;Z�]�҄TY9f׫ײ��	�Y�yP��)��X�!�:�?];�a������
���P����������������?����3��� �?B�G�������+D�As�B��k�?"��a ���9$~�����0@�G����.���B��o��l�����_[������#����?��R�8)�D EFᄣ}6h_�}F`#��e%� ��DG���$��,�Q����޿2H�N���P�����c�/�������556T[�M��5�6�\>7u���ܨi&���ހ��=i,ug�Z���q"���I�{���y��M��N�-��(SJӎz=��J�͐-7q)Hv��屓�˻}�X.)s!X�4�9���aR��-��^��͎�q�j�q>4�h���z�Ԧ�n6���ݽ��/8a a����š��?[¡o� a��W����Q
���o��b��_$�?����+�_2�/�y�o�u�<��Jy���\s�]��U��-�e�����]�$l�ޖM���7��5�,�9�l*�N]�/i�/�5�W����y�5wI=�Z��k����M��V�2���5ς��Q�����$�(|��_��O�����A�Wa��/����/�����E���,$�?A�@�������b�o�ל�8X�Q�-��A�m��]�����= ������K!��:��"N�hi��!��Ϥ�T���鞖{��i5�+s�O
�(s�|,K�I��]o��Z���Eg5A���#�Kζ�-纶8/��Ӑ���g��=�V���4��jj~�LM���Zn�o�R��BFg/9��,�����a�~�H����CU�}E�s�~�掦_���ջ�i�a}̄��Ȫ}���o�H���L���m:�Z�$f�K}󼞮�b����2���mr+n�M�ׅ��H%kN�38�>[����8v'ވ�0�H�;�������|���	�q���Hw�"��X���zz����߻�_�(J��q ���/�����OZ�$|����\$����7/	RF�/ �H�/_	.�`"3�XF�<��
�]���=����<�Á_�����Ub2�]P���QG���F��w�]�[���GQj�����-W�B��l��ߏ����y��C�|6�?�t�"/b���|���hA�������E���<�/��.�|)�/��H���A��y1P"�giV��@�9%B�䋁С�0(�f�@�?��ba�~����q�����j���OS�x������a��m��&�t�����>��:�L�L\��V��� b����*x���E*p�����hX�q 꿠�꿾n�׿��$|K�~�����F����������wE^?s�9�����>H��p����>���^hѯ�8��O���.��1��gi�~���c.����{ ����x�����0�`��N�)�|i �������0�����.�R|I ��������?&������!&���������y�����"�p���;�u5\���J�oMe�+e˺R�t��Z�M2g��m7�)��2�����FϾ��k�I���VS4����z����[V�h;[�[��D����6ƶܾyj�>W_�]�m�*���K��wPQ����90ʮ�ߚ��L�z��[���9v�.�?8���|�+�2�OY��O|�,�Q�Hj᲌8�*�b���s�~�V��vZn�Sc,dyo;J�sΜ��U�e�3�ڪ��N����Zu]f�B�㉗'
S�Dv��+�S��}�vi�5�e�lU~�x�/��VG&�U���/A����^�^D���*�+vce˭�q�͌}Oݢ�ׅ|��Ńk7��h���ɖ�:�t.?��Z�~���Ko�i#d�vFy)�K��'�Jq���$��΍�>�-s�<AD�A��:����C⋽�1[�V�ʍl��v�Z ���h�7��a�/��k�(�����#��o����`Q���I�	�� ��_H������������W��}k�wJ�IY3O��4���{W��u���S�/�_��������,}�UTt{��3XgJ5W��צ�c��ܙ[�ݳ�V�b���O��/�Q���_�2~v+�z��x���}ۦ����dgh ��w*�1�O��*m����G�e�ű۳���Ar��Qc02�2��^]����A_Zv�h�j��&��L���4N��t%+�'�8捓�y��5m�7��r��,�뽭��~��U���}��py���[o���ڍ�^�,M�v��"o��ɪj�v�^�[j<B{[�|{YOEet�چ�[�ΧW�t#���Q����<]�KR���z��}�Oʱw���Y9��dS�	2��V�}���Zѳ��+�a�x�ϯ������� ��迧� �P��m�G����7����>1��$��}p��߰�=�߭\��K����ð�tm~fD��ˎ�>ݟ������m�����D��� �M�zjS�t�z;��3 ���E���f�����9 �%0�F綸_�S�﹣�6Kc�Კ4��`~Z��F���ğ�)k��lKѳ�%�U��N��(��a7I�A����� �� �Gr �x�F%]UxQ�g8��ŦK��B���3�4�Ĝ��ۻ�C�r M�v��C퍪"�̊b!o��Wɫ�� Vf'���2#,tK6%�PY:�f�џ���k�65��
�Q����2���"����@��C�/��/�����#������ �A������ ��p�������W B�1��? @�-�S�mv!�� ��k�?��{�^x���H����A�%я�@�9Z�d%�ޗ�g��cQ� :�x:@�,!�g$���S�>����o��x�+�Ѵ�7�Zc3++��/R�ڧ��0t��ryXV+ap�4�5���������Nb{�s�R���W�rS�Ø����v��P]��ׯ��,֧�����{-6dQ��+��Ԭ�zt�
5{��u���� a����š��?[¡o� a��W����Q������b��_$�?����+�_;�l�X�Z��ZZ7*+5�P��ۓsǼ|g�i���k���z�"��K�\�[���M��l����pJS�>AV�c�ږ��^�w�<%GSݶ�v���ؤ�4װ���zޞ���GA�����oA `��_��O���H�A�Wq��/����/���������,D��?��������_����M�i�M���N\w�n:?�Z��p�WM���i����hcml2��x�����%Mo�HzA�T9,���wk�ď��S���̬Z:	:�Ɓ1��@�;)?h��1����)ۈK�4k�b�N����679u�������u�5��zU-���{a��FU��u�\��w�Z,Rk�8n��y�k_f�ٮj�Ul�2�[\��:��H��6\ݪIG��*{zb8���<�2T>��ձyG��^)��Ÿ��4�3�p�Zi���L��2+M���Im(����[��u"H[����Z��?�����X���?�x%8��{����, �����?X�����+� ��/��Y���wA����ܕ4������`�+��W��
�_a�k��_����?&��0�T�������gY��;�È�@����� ������?��!������?�B*��m�G���/��F�����/<������_`��om��H����������<?��q���_��$�?K?����X������X��������?��?����?��!�_����`�+&`���|Q@��ӼLK4aؐh� �D�WB��E9�?�YFB�Nd%䥐A"
a�ߧ���h�õ���ǯ��0n����J<a���{,%�|��W�c�������gѱ��+��a�ʻ�T���|�'�Iڱm�q� B�����q�	��"$��|��dK�;y���p�y�(�[Eս����B���n� �,4���v�i�2+�1�ݕs�s�C���\�s߾i��0i7��� C�}��Ƃ��x�z�O�kC��3�b�n��y1���[��j��O���!���?��O�(��&���;���Ԟ����C����4�P���;M�����������������l��e�A%/"/P�d�T�9�B��P�"���Q�gs�392���T:���LJ��Q �����)���������Я������n��i��W�#�=�.Y��]��%�f�5r`k5X
��?w`1YO�eԎ 9�*�G˴�OA��c��Y���\_�R#U�PnJ���_��ף��:��(����Q7��"i���[���8�<z��Y�m��J�������T�?�����*��CС��%����a��������g���/�#��q�#S��1���=�?q�� t�����G�����O�����x}��P����?Щx����������p\������B'`�9��X�����w���.���?�N
��g�� �H������J���Ы��!�_z���[ѽ�?rY5CW�mCoe�V�_��/:����uF�:��p���/���k�}�U�/���H�WɀC��u�Nr�w�y�K�b��둵�u�2^��y�z�3�
W�|���r�]y�Q�戳�)wKf'�h�'p�]��u��{!�&_gY���S�o���q㉍�V7��vڕ	[et�|O�T>�[N�gڄ��ɬ>��\#�5��
Y"���6{�T����$�q��1~��W|b�(�<���֠>�7F�����N�������x��A�쿭���5~?������;	�O����<��ǧD�N���w�����!(>�)>�)>�)>�)��c��H������������m����������?�;��G������ǣW����������5�A�|�$��ں��03�O=0_�jD���>�����p�vB'Z���D*s�{�PX�l?�'�
tO�J�</"�ָѹU��ބ��Pʯ���7��L��w�S�&W�+�y�=�nL��|oF�<����7��ޫ��^��i�Fn҈ᔓp,�gC�&���xS���=��0��Rpc�{�/�d��J^����Ti�������6n�Qu8M��vz�\٬͆����#��V�����t=;Ύ~!��f+N]iu2cFX�4�:���Z�eJ���\?�۲V`끫ީs���)��y'��+~{V�l���c��r.O؝�̯���.�+b�i�|1S���t�E��Z����gI��}���������I�dr�}>=�''��<[��a���A~�+I��u�Ռ5o\��h	Q���|��7�z�%���g�٥��w�x��I�Ԟ����B'`����q-���(��o���?�D��b�� tJ������4��d�Rҹ����d:�� 	)'ee9'˩LJ�de:%�dJ���T>%������t
�������?������ڸ:]��J���XNni��W�9�?O-��X��Ӥ����售�d:��$L�Az���5��(~Q"F��؞ݬZ��lZ����%��4G�B�_k��5�i���Z���Ϊ"*������)�����ǣ#���O��Na������I�|�����?,7���c7�oH�����w<�����h=�*�/͡�պ�7�v���g5[���x<��]�X���j�LS�Z+�g����\��뒘�ON���2ϯ�9�Ȏ�K��t�׆ϕU������ȭa[`�*��I�t����Nc�������YL���b��3�)�������_���x�W��+�����q�?�x:	�/�}f��ұ�wz���#�O�<��oi�[�Yz�lmU�]X����W�GY��*���E���ښ��= D��'� ����= �T�KC��{-Uoxu �^���W��y͵R�{ˤg�ll�D뼘��~�V4��n�S��e�\kt�l����l�q-J�_��1����4�p��T�>���{컡�>�?x_�h���_�?`s�P��I��7lh�"[NjZ6J�W�rԽk_C�~Nh�\�q�Lu�N��W�:��'�ۓ:w�M��T��]M�wfx��@f�B���*Y��E1�S��{�;��eN�Gj�R3	+�����3m�X���|v�foͧ2��έz��w�a��V\�J׳�u�NeO���?����87^-���dz��4Cfc�?} ��Xۺ6qA���+{� �a�Ns@r�$���mn.j�M^Th���C��Q��:A�|(�ů#���i+�L�\�TuS��T`m `.����J���@�Wi�>� ��9���/@C��˭ (XsQ7/������1ǳ��A/v!�Ѐt���e5t!@�`��w�MP���'n���f�8���zA޼[��"����jԻ
o��Qr���-��ƿo����w�;��r  ��)JD�����e�E*�-B$��M��<;�Ԟ�U�:�<���u󾈋�p�A�|����r���P�D��-�q�8�˵u� ��ָlG�UBY]�h�0�H�><�8 >w����P�z�@��E�R8�W��H1��+A�'����,3���� 2D�KP<@�����!aylA�<��@=w	?�7��qk��g�_���w_��w��?����-��BI����L����ؒ\����v)zAն�Ae�;?�F����	�PT�W`Cg�m	�u��D{m���jY(M���b��Jy.:�z��Gy�,Ν�΍2n:�y(�B$T�v��t����쭒$�/�߿�l4����v��m�J; Ba՘[6��ĝ���ХlCT+5ٝ��>�0��@��H<�òf�>��g����O�xx�3�j#v#�C���Q/q-Mo.�a�0	���/_��؀w�P��
\��]|�%b���{��Q��\ۓݐ?V�ϛ>���Q���4��FE`�ƴ\0�\7���E+6�40��N"~�;'\��|e�a����,=6:�+��iODm(�r}��_Py�2��l�Irz;�n�Tt��7�%H?$<�B����a���Y���������S�s�KQ�v$��@�e|��h4%а[,x�7�T��u�t�+N����w-��%�����'�y��3&��Ba8G�&@�C��EܹJ�	��p�lY�S�o�b����W[��sW���¶T٫|$9��YB� �\X���\ΰ�H<�ׅ�OH���9��4��a�p%�V�L�0I,�����v�r�`���_A݂[4�N��|�/����x�0��s�t:��b�?�GC�%�D",��1d�A��Т�E���T4$�����G�×�5G&� 34��m�ء}��l���-7��U�rr/�H&�<�:��5X�bOe��{
G⋕�
�Lu�x*���
�+G�iETS�D�����i(�S0�V3U��J)Y�EZJ���"���ψ��"�o�4����Y�L3��Oh�0�@/�3A�>=�OhW��@L�W���o�c�C�3��1�T^�2iQ�$�ɑYET(22)�EQ�d�<̒�L�DI�g
�)Ԓ�<d��3"D.$7x�]��B����2�9�j�ď�t�b��ou���xh߆v�>)F�`�sM|�����hl���Զ�)$�%�!t��m�Y�	�v�@��^�V���[(t�n��L����ۭt�B��,\a	y-�~��X/Y/�����V�pY,���܅J�y��Q��߲g�W�Ut�$���Ԭ��N��-'5��yR K��jWi����EG*Nb='�	v(���t�\;�v5�z���R�m��28�=r��y�O[����~yߟ����M��fG�B^�4��+�'����l��7�9C�(\���uP��V���]y���L&�8Β\�v���ȶJ8��<��E���ͻѶZI��n�&_E�����l+�ۆ�6;�:z����n;���Fm��c&�r܆g�+��,�� J��n��	���c9�+\!7W�����}�\�w��6$���2��1�TA�m�Q�r�r9t�J����n'��NI���Bt�+S^��?��}��?Yn0��V�[w.��8���}hΗFJ|/	F��?ZG��7O�I�c�{�=pT�n��*�uQs&�&�����s��O���?�ƾ��s�h+�o��	g�e�����(������GQi�I�-���w ��oII7���L�a���L���hۖ�,l�t�hts�;��K�L�PƳ�Dǿ<X֯�����?0�-JA�[�lOo"�E�-{� ��t��3���Aw�'�>�� �|�m�;��w����/g�/_A�0���C��`�� �������q���B�E�
�����>+�)�r�<{�ӣʼ)3�"����2��T�.$>��+Rm���C}�4[�N��h���hX�����6T��'�׭�G�CSX������ڞ���睛 #�_����hdy��Ius>�(��eퟚފ��k-~�1���?��g�E�R4�:ͤb�?� �f ����:G�� �D��ό	ϲ�	��8'�o���+x�X0��#k��@�������#������l��� ���G��]�yŅ��B��	�g��D
� W�:2�DS�oK2A1���	���3�ߒH���g�����<�}q�a�@�g࢘ ��@\>���J�e���ƅQ�����Bp(�?[?�|�Z����gߣ%���֊�,�����x��~:A~�삒Cpx(���5.�Ɲ���������k_T�x`ֳõ/q	w�&҂�o�zz���}>����lw[څbV�A��<�x1�a ��&���}o:-miY��u��w�y�o����c�J,�\�83����p�!�g�p����.�Q����77���{xW�$%��X����Bl-KIψ|	Ҫy�\c}p�H-≯ŲlAn��;�R]�)�)ag�~s<�BjGD����-�\�j��˝�eUa`[��2j�Z�1d��s+I��SGBY�oL,�_[��%�b��U��-�wy�r�g�Yn�x&�}�xτp?�C��W�&�~9��v���sDJ�|3�&�ġO⡙�h�a�M\���u�Z�@G�@�����U����(R�f����J���+44�0Ge�Js��>�]�i.K;6�7����f}h���K�w!x�=*����n�C�A�cYut���}��Z]�!�%�Ґl��&���P���]�X���>�V��Td���D��5wi3��𞜙;�p��W��3k'z�w�=�o�0�z��l�����=������Ջ���ܗ^�?�["y�*���A_�f��苚&c$�[�tgW�Ӗ ��;�H�\+���[L��:�ޙ���\��Z�K�����Kt��#��?Vy�������v�O���>�D'N:/�e,�(K�X�3�mP��s~��ϣtz��g&��`0��`0��`0���0��0 0 