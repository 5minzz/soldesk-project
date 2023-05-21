
 <?php
    include("db_connect.php");
    ?>
 <?php
    $no = $_GET['no'];
    // 저장 돼있는 파일삭제. 
    $read_sql = "select * from video where no = $no";
    $read_result = mysqli_query($conn, $read_sql);
    $row = mysqli_fetch_array($read_result);
    $title = $row['val'];
echo $title ;
    require '/var/www/html/vendor/autoload.php';

    use Aws\S3\S3Client;
    use Aws\Exception\AwsException;
    use Aws\Credentials\CredentialProvider;

    // Instantiate an S3 client
    $sharedConfig = [

        'region' => 'ap-northeast-2',
        'version' => 'latest',
        'credentials' => [
            'key'    => '***',
            'secret' => '**',
        ]
    ];

    // Create an SDK class used to share configuration across clients.
    $sdk = new Aws\Sdk($sharedConfig);

    // Use an Aws\Sdk class to create the S3Client object.
    $s3Client = $sdk->createS3();

    try {
        $list = $s3Client->deleteObject([
            'Bucket' => 'jimssa-video',
            'Key' => $_GET['Key']
        ]);
    } catch (S3Exception $e) {
        print_r($e);
    }




    // 데이터베이스 데이터삭제.
    $del_sql = "DELETE FROM video where no='$no'";
    $query_result = mysqli_query($conn, $del_sql);
    $a = "SET @COUNT = 0";
    $b = "UPDATE video SET no = @COUNT:=@COUNT+1";
    $c = "ALTER TABLE video AUTO_INCREMENT=1";
    mysqli_query($conn, $a);
    mysqli_query($conn, $b);
    mysqli_query($conn, $c);
    if (!$query_result) {
        echo "sql command error ocurred \n";
        mysqli_error();
        exit;
    } else {

        echo " <script >              
    alert('성공적으로 삭제 되었습니다.');
  window.location = './index.php';
      </script>";
    }
?>
