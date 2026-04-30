"""
AWS S3 file storage utilities for MoodLite
Handles upload, download, and deletion of files to/from S3
"""
import os
import boto3
from flask import current_app

s3_client = None


def get_s3_client():
    """Get or create S3 client"""
    global s3_client
    if s3_client is None:
        s3_client = boto3.client(
            's3',
            aws_access_key_id=current_app.config.get('AWS_ACCESS_KEY_ID'),
            aws_secret_access_key=current_app.config.get('AWS_SECRET_ACCESS_KEY'),
            region_name=current_app.config.get('AWS_S3_REGION', 'us-east-1')
        )
    return s3_client


def upload_file_to_s3(file, filename):
    """
    Upload file to S3
    
    Args:
        file: File object from request.files
        filename: Name to store as in S3
    
    Returns:
        bool: True if successful, False otherwise
    """
    try:
        s3 = get_s3_client()
        bucket = current_app.config.get('AWS_S3_BUCKET')
        
        if not bucket:
            print("AWS_S3_BUCKET not configured")
            return False
        
        s3.upload_fileobj(
            file,
            bucket,
            filename,
            ExtraArgs={'ContentType': file.content_type or 'application/octet-stream'}
        )
        print(f"Successfully uploaded {filename} to S3")
        return True
    except Exception as e:
        print(f"S3 upload error: {e}")
        return False


def get_download_url(filename, expires=3600):
    """
    Generate signed URL for downloading file from S3
    
    Args:
        filename: S3 object key
        expires: URL expiration time in seconds (default: 1 hour)
    
    Returns:
        str: Pre-signed URL or None if error
    """
    try:
        s3 = get_s3_client()
        bucket = current_app.config.get('AWS_S3_BUCKET')
        
        if not bucket:
            print("AWS_S3_BUCKET not configured")
            return None
        
        url = s3.generate_presigned_url(
            'get_object',
            Params={'Bucket': bucket, 'Key': filename},
            ExpiresIn=expires
        )
        return url
    except Exception as e:
        print(f"S3 URL generation error: {e}")
        return None


def delete_file_from_s3(filename):
    """
    Delete file from S3
    
    Args:
        filename: S3 object key
    
    Returns:
        bool: True if successful, False otherwise
    """
    try:
        s3 = get_s3_client()
        bucket = current_app.config.get('AWS_S3_BUCKET')
        
        if not bucket:
            print("AWS_S3_BUCKET not configured")
            return False
        
        s3.delete_object(Bucket=bucket, Key=filename)
        print(f"Successfully deleted {filename} from S3")
        return True
    except Exception as e:
        print(f"S3 delete error: {e}")
        return False


def copy_file_in_s3(source_key, dest_key):
    """
    Copy file within S3
    
    Args:
        source_key: Source object key
        dest_key: Destination object key
    
    Returns:
        bool: True if successful, False otherwise
    """
    try:
        s3 = get_s3_client()
        bucket = current_app.config.get('AWS_S3_BUCKET')
        
        if not bucket:
            print("AWS_S3_BUCKET not configured")
            return False
        
        s3.copy_object(
            Bucket=bucket,
            CopySource={'Bucket': bucket, 'Key': source_key},
            Key=dest_key
        )
        print(f"Successfully copied {source_key} to {dest_key} in S3")
        return True
    except Exception as e:
        print(f"S3 copy error: {e}")
        return False


def list_files_in_s3(prefix=''):
    """
    List files in S3 bucket with optional prefix
    
    Args:
        prefix: S3 prefix/folder path
    
    Returns:
        list: List of file keys or empty list if error
    """
    try:
        s3 = get_s3_client()
        bucket = current_app.config.get('AWS_S3_BUCKET')
        
        if not bucket:
            return []
        
        response = s3.list_objects_v2(Bucket=bucket, Prefix=prefix)
        
        if 'Contents' not in response:
            return []
        
        return [obj['Key'] for obj in response['Contents']]
    except Exception as e:
        print(f"S3 list error: {e}")
        return []


def get_file_info(filename):
    """
    Get file information from S3
    
    Args:
        filename: S3 object key
    
    Returns:
        dict: File metadata (size, modified date, etc.) or None if error
    """
    try:
        s3 = get_s3_client()
        bucket = current_app.config.get('AWS_S3_BUCKET')
        
        if not bucket:
            return None
        
        response = s3.head_object(Bucket=bucket, Key=filename)
        
        return {
            'size': response.get('ContentLength'),
            'modified': response.get('LastModified'),
            'content_type': response.get('ContentType'),
            'etag': response.get('ETag')
        }
    except Exception as e:
        print(f"S3 head object error: {e}")
        return None
