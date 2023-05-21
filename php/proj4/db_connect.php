<?php
require '/var/www/html/vendor/autoload.php';

use Aws\Rds\RdsClient;
use Aws\Exception\AwsException;

$rdsClient = new Aws\Rds\RdsClient([
    'version' => 'latest',
    'region' => 'ap-northeast-2',
    'credentials' => [
     'key'    => '***',
        'secret' => '***',
    ]
]);

try {
    $result = $rdsClient->describeDBInstances(['DBInstanceIdentifier' => 'project-db']);
    $endpoint = $result['DBInstances'][0]['Endpoint']['Address'];
    echo "$endpoint <br>"; //지우기
    echo " Raw Result <br>"; //지우기
    #  var_dump($result);
} catch (AwsException $e) {
    // output error message if fails
    echo $e->getMessage();
    echo "\n";
}
#import awscli.* #
#                echo "현재 메인 rds server ip = maindb()";
#                $servername= maindb($aws_mainDB.ip) ;
$servername = $endpoint;
#$servername = "10.0.1.10";
#               10.0.3.10
$username = "root";
$password2 = "mypass123";
$db_name = "projectdb"; //교체

// Create connection
$conn = mysqli_connect($servername, $username, $password2, $db_name);
mysqli_set_charset($conn, "utf8");
// Create connection
if (!$conn) {
    die("connection failed: " . mysqli_connect_error());
} else {
    echo "servername = $servername <br>"; //지우기
    echo "성공"; //지우기
}
